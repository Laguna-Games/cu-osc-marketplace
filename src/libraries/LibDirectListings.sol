// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import {IDirectListings} from '../interfaces/IMarketplace.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IPlatformFee} from '../interfaces/IPlatformFee.sol';
import {LibCurrencyTransfer} from './LibCurrencyTransfer.sol';
import {LibRoyalty} from './LibRoyalty.sol';
import {LibMarketplacePermissions} from './LibMarketplacePermissions.sol';
import {LibEvents} from './LibEvents.sol';
import {LibMarketplace} from './LibMarketplace.sol';

library LibDirectListings {
    /// @custom:storage-location erc7201:direct.listings.storage
    /// @dev storage slot for the direct listings storage.
    bytes32 internal constant DIRECT_LISTINGS_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('CryptoUnicorns.Marketplace.LibDirectListings.Storage')) - 1)) &
            ~bytes32(uint256(0xff));

    struct DirectListingsStorage {
        uint256 totalListings;
        mapping(uint256 => IDirectListings.Listing) listings;
        mapping(uint256 => mapping(address => bool)) isBuyerApprovedForListing;
        mapping(uint256 => mapping(address => uint256)) currencyPriceForListing;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next listing Id.
    function _getNextListingId() internal returns (uint256 id) {
        directListingsStorage().totalListings += 1;
        id = directListingsStorage().totalListings;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (IDirectListings.TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = IDirectListings.TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = IDirectListings.TokenType.ERC721;
        } else {
            revert('Marketplace: listed token must be ERC1155 or ERC721.');
        }
    }

    /// @dev Checks whether the listing creator owns and has approved marketplace to transfer listed tokens.
    function _validateNewListing(
        IDirectListings.ListingParameters memory _params,
        IDirectListings.TokenType _tokenType
    ) internal view {
        require(_params.quantity > 0, 'Marketplace: listing zero quantity.');
        require(
            _params.quantity == 1 || _tokenType == IDirectListings.TokenType.ERC1155,
            'Marketplace: listing invalid quantity.'
        );

        require(
            _validateOwnershipAndApproval(
                msg.sender,
                _params.assetContract,
                _params.tokenId,
                _params.quantity,
                _tokenType
            ),
            'Marketplace: not owner or approved tokens.'
        );
    }

    /// @dev Checks whether the listing exists, is active, and if the lister has sufficient balance.
    function _validateExistingListing(
        IDirectListings.Listing memory _targetListing
    ) internal view returns (bool isValid) {
        isValid =
            _targetListing.startTimestamp <= block.timestamp &&
            _targetListing.endTimestamp > block.timestamp &&
            _targetListing.status == IDirectListings.Status.CREATED &&
            _validateOwnershipAndApproval(
                _targetListing.listingCreator,
                _targetListing.assetContract,
                _targetListing.tokenId,
                _targetListing.quantity,
                _targetListing.tokenType
            );
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Marketplace to transfer NFTs.
    function _validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        IDirectListings.TokenType _tokenType
    ) internal view returns (bool isValid) {
        address market = address(this);

        if (_tokenType == IDirectListings.TokenType.ERC1155) {
            isValid =
                IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity &&
                IERC1155(_assetContract).isApprovedForAll(_tokenOwner, market);
        } else if (_tokenType == IDirectListings.TokenType.ERC721) {
            address owner;
            address operator;

            // failsafe for reverts in case of non-existent tokens
            try IERC721(_assetContract).ownerOf(_tokenId) returns (address _owner) {
                owner = _owner;

                // Nesting the approval check inside this try block, to run only if owner check doesn't revert.
                // If the previous check for owner fails, then the return value will always evaluate to false.
                try IERC721(_assetContract).getApproved(_tokenId) returns (address _operator) {
                    operator = _operator;
                } catch {}
            } catch {}

            isValid =
                owner == _tokenOwner &&
                (operator == market || IERC721(_assetContract).isApprovedForAll(_tokenOwner, market));
        }
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Markeplace to transfer the appropriate amount of currency
    function _validateERC20BalAndAllowance(address _tokenOwner, address _currency, uint256 _amount) internal view {
        require(
            IERC20(_currency).balanceOf(_tokenOwner) >= _amount &&
                IERC20(_currency).allowance(_tokenOwner, address(this)) >= _amount,
            '!BAL20'
        );
    }

    /// @dev Transfers tokens listed for sale in a direct or auction listing.
    function _transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        IDirectListings.Listing memory _listing
    ) internal {
        if (_listing.tokenType == IDirectListings.TokenType.ERC1155) {
            IERC1155(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, _quantity, '');
        } else if (_listing.tokenType == IDirectListings.TokenType.ERC721) {
            IERC721(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, '');
        }
    }

    function enforceOnlyListingCreator(uint256 _listingId) internal view {
        require(
            directListingsStorage().listings[_listingId].listingCreator == msg.sender,
            'Marketplace: not listing creator.'
        );
    }

    function enforceOnlyExistingListing(uint256 _listingId) internal view {
        require(
            directListingsStorage().listings[_listingId].status == IDirectListings.Status.CREATED,
            'Marketplace: invalid listing.'
        );
    }

    /// @notice List NFTs (ERC721 or ERC1155) for sale at a fixed price.
    function createListing(IDirectListings.ListingParameters calldata _params) internal returns (uint256 listingId) {
        LibMarketplacePermissions.onlyAssetRole(_params.assetContract);
        LibMarketplace.enforceCurrencyApproval(_params.currency);
        listingId = LibDirectListings._getNextListingId();
        address listingCreator = msg.sender;
        IDirectListings.TokenType tokenType = LibDirectListings._getTokenType(_params.assetContract);

        uint128 startTime = _params.startTimestamp;
        uint128 endTime = _params.endTimestamp;
        require(startTime < endTime, 'Marketplace: endTimestamp not greater than startTimestamp.');
        if (startTime < block.timestamp) {
            require(startTime + 60 minutes >= block.timestamp, 'Marketplace: invalid startTimestamp.');

            startTime = uint128(block.timestamp);
            endTime = endTime == type(uint128).max
                ? endTime
                : startTime + (_params.endTimestamp - _params.startTimestamp);
        }

        LibDirectListings._validateNewListing(_params, tokenType);

        IDirectListings.Listing memory listing = IDirectListings.Listing({
            listingId: listingId,
            listingCreator: listingCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            pricePerToken: _params.pricePerToken,
            startTimestamp: startTime,
            endTimestamp: endTime,
            tokenType: tokenType,
            status: IDirectListings.Status.CREATED
        });

        directListingsStorage().listings[listingId] = listing;

        emit LibEvents.NewListing(listingCreator, listingId, _params.assetContract, listing);
    }

    /// @notice Update parameters of a listing of NFTs.
    function updateListing(uint256 _listingId, IDirectListings.ListingParameters memory _params) internal {
        enforceOnlyExistingListing(_listingId);
        enforceOnlyListingCreator(_listingId);
        LibMarketplace.enforceCurrencyApproval(_params.currency);
        LibMarketplacePermissions.onlyAssetRole(_params.assetContract);
        address listingCreator = msg.sender;
        IDirectListings.Listing memory listing = directListingsStorage().listings[_listingId];
        IDirectListings.TokenType tokenType = LibDirectListings._getTokenType(_params.assetContract);

        require(listing.endTimestamp > block.timestamp, 'Marketplace: listing expired.');

        require(
            listing.assetContract == _params.assetContract && listing.tokenId == _params.tokenId,
            'Marketplace: cannot update what token is listed.'
        );

        uint128 startTime = _params.startTimestamp;
        uint128 endTime = _params.endTimestamp;
        require(startTime < endTime, 'Marketplace: endTimestamp not greater than startTimestamp.');
        require(
            listing.startTimestamp > block.timestamp ||
                (startTime == listing.startTimestamp && endTime > block.timestamp),
            'Marketplace: listing already active.'
        );
        if (startTime != listing.startTimestamp && startTime < block.timestamp) {
            require(startTime + 60 minutes >= block.timestamp, 'Marketplace: invalid startTimestamp.');

            startTime = uint128(block.timestamp);

            endTime = endTime == listing.endTimestamp || endTime == type(uint128).max
                ? endTime
                : startTime + (_params.endTimestamp - _params.startTimestamp);
        }

        {
            uint256 _approvedCurrencyPrice = directListingsStorage().currencyPriceForListing[_listingId][
                _params.currency
            ];
            require(
                _approvedCurrencyPrice == 0 || _params.pricePerToken == _approvedCurrencyPrice,
                'Marketplace: price different from approved price'
            );
        }

        LibDirectListings._validateNewListing(_params, tokenType);

        listing = IDirectListings.Listing({
            listingId: _listingId,
            listingCreator: listingCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            pricePerToken: _params.pricePerToken,
            startTimestamp: startTime,
            endTimestamp: endTime,
            tokenType: tokenType,
            status: IDirectListings.Status.CREATED
        });

        directListingsStorage().listings[_listingId] = listing;

        emit LibEvents.UpdatedListing(listingCreator, _listingId, _params.assetContract, listing);
    }

    /// @notice Cancel a listing.
    function cancelListing(uint256 _listingId) internal {
        enforceOnlyExistingListing(_listingId);
        enforceOnlyListingCreator(_listingId);
        directListingsStorage().listings[_listingId].status = IDirectListings.Status.CANCELLED;
        emit LibEvents.CancelledListing(msg.sender, _listingId);
    }

    /// @notice Buy NFTs from a listing.
    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice,
        uint256 _targetTotalPrice,
        bool _isMultipleBuy
    ) internal {
        enforceOnlyExistingListing(_listingId);
        IDirectListings.Listing memory listing = directListingsStorage().listings[_listingId];
        address buyer = msg.sender;

        require(_quantity > 0 && _quantity <= listing.quantity, 'Buying invalid quantity');
        require(
            block.timestamp < listing.endTimestamp && block.timestamp >= listing.startTimestamp,
            'not within sale window.'
        );

        require(
            LibDirectListings._validateOwnershipAndApproval(
                listing.listingCreator,
                listing.assetContract,
                listing.tokenId,
                _quantity,
                listing.tokenType
            ),
            'Marketplace: not owner or approved tokens.'
        );

        require(_targetTotalPrice == _expectedTotalPrice, 'Unexpected total price');

        // Check: buyer owns and has approved sufficient currency for sale.
        if (_currency == LibCurrencyTransfer.NATIVE_TOKEN) {
            if (!_isMultipleBuy) {
                require(msg.value == _targetTotalPrice, 'Marketplace: msg.value must exactly be the total price.');
            }
        } else {
            if (!_isMultipleBuy) {
                require(msg.value == 0, 'Marketplace: invalid native tokens sent.');
            }
            LibDirectListings._validateERC20BalAndAllowance(buyer, _currency, _targetTotalPrice);
        }

        if (listing.quantity == _quantity) {
            directListingsStorage().listings[_listingId].status = IDirectListings.Status.COMPLETED;
        }
        directListingsStorage().listings[_listingId].quantity -= _quantity;

        LibCurrencyTransfer._payout(
            buyer,
            listing.listingCreator,
            _currency,
            _targetTotalPrice,
            listing.assetContract,
            listing.tokenId,
            LibMarketplace.nativeTokenWrapper()
        );
        LibDirectListings._transferListingTokens(listing.listingCreator, _buyFor, _quantity, listing);

        emit LibEvents.NewSale(
            listing.listingCreator,
            listing.listingId,
            listing.assetContract,
            listing.tokenId,
            buyer,
            _quantity,
            _targetTotalPrice
        );
    }

    function getTargetTotalPrice(
        uint256 _listingId,
        uint256 _quantity,
        address _currency
    ) internal view returns (uint256 targetTotalPrice) {
        IDirectListings.Listing memory listing = directListingsStorage().listings[_listingId];
        if (directListingsStorage().currencyPriceForListing[_listingId][_currency] > 0) {
            targetTotalPrice = _quantity * directListingsStorage().currencyPriceForListing[_listingId][_currency];
        } else {
            require(_currency == listing.currency, 'Paying in invalid currency.');
            targetTotalPrice = _quantity * listing.pricePerToken;
        }
        return targetTotalPrice;
    }

    function buyFromMultipleListings(
        uint256[] memory _listingIds,
        address _buyFor,
        uint256[] memory _quantities,
        address[] memory _currencies,
        uint256[] memory _expectedTotalPrices
    ) internal {
        require(
            (_listingIds.length == _quantities.length) && (_currencies.length == _expectedTotalPrices.length),
            'Marketplace: invalid input lengths.'
        );

        uint256 totalListings = _listingIds.length;
        uint256 targetETHTotalPrice;
        uint256[] memory targetTotalPrices = new uint256[](totalListings);

        for (uint256 i = 0; i < totalListings; i++) {
            if (_currencies[i] == LibCurrencyTransfer.NATIVE_TOKEN) {
                targetETHTotalPrice += getTargetTotalPrice(_listingIds[i], _quantities[i], _currencies[i]);
            }
            targetTotalPrices[i] = getTargetTotalPrice(_listingIds[i], _quantities[i], _currencies[i]);
        }

        require(msg.value == targetETHTotalPrice, 'Marketplace: msg.value must exactly be the total ETH price.');

        for (uint256 i = 0; i < totalListings; i++) {
            buyFromListing(
                _listingIds[i],
                _buyFor,
                _quantities[i],
                _currencies[i],
                _expectedTotalPrices[i],
                targetTotalPrices[i],
                true
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total number of listings created.
     *  @dev At any point, the return value is the ID of the next listing created.
     */
    function totalListings() internal view returns (uint256) {
        return directListingsStorage().totalListings;
    }

    /// @notice Returns whether a buyer is approved for a listing.
    function isBuyerApprovedForListing(uint256 _listingId, address _buyer) internal view returns (bool) {
        return directListingsStorage().isBuyerApprovedForListing[_listingId][_buyer];
    }

    /// @notice Returns whether a currency is approved for a listing.
    function isCurrencyApprovedForListing(uint256 _listingId, address _currency) internal view returns (bool) {
        return directListingsStorage().currencyPriceForListing[_listingId][_currency] > 0;
    }

    /// @notice Returns the price per token for a listing, in the given currency.
    function currencyPriceForListing(uint256 _listingId, address _currency) internal view returns (uint256) {
        if (directListingsStorage().currencyPriceForListing[_listingId][_currency] == 0) {
            revert('Currency not approved for listing');
        }

        return directListingsStorage().currencyPriceForListing[_listingId][_currency];
    }

    /// @notice Returns all non-cancelled listings.
    function getAllListings(
        uint256 _startId,
        uint256 _endId
    ) internal view returns (IDirectListings.Listing[] memory _allListings) {
        require(
            _startId >= 1 && _startId <= _endId && _endId <= directListingsStorage().totalListings,
            'invalid range'
        );

        _allListings = new IDirectListings.Listing[](_endId - _startId + 1);

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _allListings[i - _startId] = directListingsStorage().listings[i];
        }
    }

    /**
     *  @notice Returns all valid listings between the start and end Id (both inclusive) provided.
     *          A valid listing is where the listing creator still owns and has approved Marketplace
     *          to transfer the listed NFTs.
     */
    function getAllValidListings(
        uint256 _startId,
        uint256 _endId
    ) internal view returns (IDirectListings.Listing[] memory _validListings) {
        require(
            _startId >= 1 && _startId <= _endId && _endId <= directListingsStorage().totalListings,
            'invalid range'
        );

        IDirectListings.Listing[] memory _listings = new IDirectListings.Listing[](_endId - _startId + 1);
        uint256 _listingCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _listings[i - _startId] = directListingsStorage().listings[i];
            if (LibDirectListings._validateExistingListing(_listings[i - _startId])) {
                _listingCount += 1;
            }
        }

        _validListings = new IDirectListings.Listing[](_listingCount);
        uint256 index = 0;
        uint256 count = _listings.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (LibDirectListings._validateExistingListing(_listings[i])) {
                _validListings[index++] = _listings[i];
            }
        }
    }

    /// @notice Returns a listing at a particular listing ID.
    function getListing(uint256 _listingId) internal view returns (IDirectListings.Listing memory listing) {
        listing = directListingsStorage().listings[_listingId];
    }

    function directListingsStorage() internal pure returns (DirectListingsStorage storage dls) {
        bytes32 position = DIRECT_LISTINGS_STORAGE_POSITION;
        assembly {
            dls.slot := position
        }
    }
}
