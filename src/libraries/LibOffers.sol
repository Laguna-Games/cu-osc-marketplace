// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';

import {IOffers} from '../interfaces/IMarketplace.sol';
import {IPlatformFee} from '../interfaces/IPlatformFee.sol';
import {IRoyaltyPayments} from '../interfaces/IRoyaltyPayments.sol';
import {LibMarketplacePermissions} from './LibMarketplacePermissions.sol';
import {LibMarketplace} from './LibMarketplace.sol';
import {LibCurrencyTransfer} from './LibCurrencyTransfer.sol';
import {LibEvents} from './LibEvents.sol';

library LibOffers {
    /// @custom:storage-location erc7201:offers.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("offers.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OFFERS_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('CryptoUnicorns.Marketplace.LibOffers.Storage')) - 1)) &
            ~bytes32(uint256(0xff));

    struct OffersStorage {
        uint256 totalOffers;
        mapping(uint256 => IOffers.Offer) offers;
    }

    function enforceOnlyOfferor(uint256 _offerId) internal view {
        require(offersStorage().offers[_offerId].offeror == msg.sender, '!Offeror');
    }

    function enforceOnlyExistingOffer(uint256 _offerId) internal view {
        require(offersStorage().offers[_offerId].status == IOffers.Status.CREATED, 'Marketplace: invalid offer.');
    }

    /*///////////////////////////////////////////////////////////////
                            internal functions
    //////////////////////////////////////////////////////////////*/

    function makeOffer(IOffers.OfferParams memory _params) internal returns (uint256 _offerId) {
        LibMarketplacePermissions.onlyAssetRole(_params.assetContract);
        LibMarketplace.enforceCurrencyApproval(_params.currency);
        _offerId = _getNextOfferId();
        address _offeror = msg.sender;
        IOffers.TokenType _tokenType = _getTokenType(_params.assetContract);

        _validateNewOffer(_params, _tokenType);

        IOffers.Offer memory _offer = IOffers.Offer({
            offerId: _offerId,
            offeror: _offeror,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            tokenType: _tokenType,
            quantity: _params.quantity,
            currency: _params.currency,
            totalPrice: _params.totalPrice,
            expirationTimestamp: _params.expirationTimestamp,
            status: IOffers.Status.CREATED
        });

        offersStorage().offers[_offerId] = _offer;

        emit LibEvents.NewOffer(_offeror, _offerId, _params.assetContract, _offer);
    }

    function cancelOffer(uint256 _offerId) internal {
        enforceOnlyExistingOffer(_offerId);
        enforceOnlyOfferor(_offerId);
        offersStorage().offers[_offerId].status = IOffers.Status.CANCELLED;

        emit LibEvents.CancelledOffer(msg.sender, _offerId);
    }

    function acceptOffer(uint256 _offerId) internal {
        enforceOnlyExistingOffer(_offerId);
        IOffers.Offer memory _targetOffer = offersStorage().offers[_offerId];

        require(_targetOffer.expirationTimestamp > block.timestamp, 'EXPIRED');

        require(
            _validateERC20BalAndAllowance(_targetOffer.offeror, _targetOffer.currency, _targetOffer.totalPrice),
            'Marketplace: insufficient currency balance.'
        );

        _validateOwnershipAndApproval(
            msg.sender,
            _targetOffer.assetContract,
            _targetOffer.tokenId,
            _targetOffer.quantity,
            _targetOffer.tokenType
        );

        offersStorage().offers[_offerId].status = IOffers.Status.COMPLETED;

        LibCurrencyTransfer._payout(
            _targetOffer.offeror,
            msg.sender,
            _targetOffer.currency,
            _targetOffer.totalPrice,
            _targetOffer.assetContract,
            _targetOffer.tokenId,
            address(0)
        );
        _transferOfferTokens(msg.sender, _targetOffer.offeror, _targetOffer.quantity, _targetOffer);

        emit LibEvents.AcceptedOffer(
            _targetOffer.offeror,
            _targetOffer.offerId,
            _targetOffer.assetContract,
            _targetOffer.tokenId,
            msg.sender,
            _targetOffer.quantity,
            _targetOffer.totalPrice
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns total number of offers
    function totalOffers() internal view returns (uint256) {
        return offersStorage().totalOffers;
    }

    /// @dev Returns existing offer with the given uid.
    function getOffer(uint256 _offerId) internal view returns (IOffers.Offer memory _offer) {
        _offer = offersStorage().offers[_offerId];
    }

    /// @dev Returns all existing offers within the specified range.
    function getAllOffers(uint256 _startId, uint256 _endId) internal view returns (IOffers.Offer[] memory _allOffers) {
        require(_startId >= 1 && _startId <= _endId && _endId <= offersStorage().totalOffers, 'invalid range');

        _allOffers = new IOffers.Offer[](_endId - _startId + 1);

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _allOffers[i - _startId] = offersStorage().offers[i];
        }
    }

    /// @dev Returns offers within the specified range, where offeror has sufficient balance.
    function getAllValidOffers(
        uint256 _startId,
        uint256 _endId
    ) internal view returns (IOffers.Offer[] memory _validOffers) {
        require(_startId >= 1 && _startId <= _endId && _endId <= offersStorage().totalOffers, 'invalid range');

        IOffers.Offer[] memory _offers = new IOffers.Offer[](_endId - _startId + 1);
        uint256 _offerCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _offers[j] = offersStorage().offers[i];
            if (_validateExistingOffer(_offers[j])) {
                _offerCount += 1;
            }
        }

        _validOffers = new IOffers.Offer[](_offerCount);
        uint256 index = 0;
        uint256 count = _offers.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (_validateExistingOffer(_offers[i])) {
                _validOffers[index++] = _offers[i];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next offer Id.
    function _getNextOfferId() internal returns (uint256 id) {
        offersStorage().totalOffers += 1;
        id = offersStorage().totalOffers;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (IOffers.TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = IOffers.TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = IOffers.TokenType.ERC721;
        } else {
            revert('Marketplace: token must be ERC1155 or ERC721.');
        }
    }

    /// @dev Checks whether the auction creator owns and has approved marketplace to transfer auctioned tokens.
    function _validateNewOffer(IOffers.OfferParams memory _params, IOffers.TokenType _tokenType) internal view {
        require(_params.totalPrice > 0, 'zero price.');
        require(_params.quantity > 0, 'Marketplace: wanted zero tokens.');
        require(
            _params.quantity == 1 || _tokenType == IOffers.TokenType.ERC1155,
            'Marketplace: wanted invalid quantity.'
        );
        require(
            _params.expirationTimestamp + 60 minutes > block.timestamp,
            'Marketplace: invalid expiration timestamp.'
        );

        require(
            _validateERC20BalAndAllowance(msg.sender, _params.currency, _params.totalPrice),
            'Marketplace: insufficient currency balance.'
        );
    }

    /// @dev Checks whether the offer exists, is active, and if the offeror has sufficient balance.
    function _validateExistingOffer(IOffers.Offer memory _targetOffer) internal view returns (bool isValid) {
        isValid =
            _targetOffer.expirationTimestamp > block.timestamp &&
            _targetOffer.status == IOffers.Status.CREATED &&
            _validateERC20BalAndAllowance(_targetOffer.offeror, _targetOffer.currency, _targetOffer.totalPrice);
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Marketplace to transfer NFTs.
    function _validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        IOffers.TokenType _tokenType
    ) internal view {
        address market = address(this);
        bool isValid;

        if (_tokenType == IOffers.TokenType.ERC1155) {
            isValid =
                IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity &&
                IERC1155(_assetContract).isApprovedForAll(_tokenOwner, market);
        } else if (_tokenType == IOffers.TokenType.ERC721) {
            isValid =
                IERC721(_assetContract).ownerOf(_tokenId) == _tokenOwner &&
                (IERC721(_assetContract).getApproved(_tokenId) == market ||
                    IERC721(_assetContract).isApprovedForAll(_tokenOwner, market));
        }

        require(isValid, 'Marketplace: not owner or approved tokens.');
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Markeplace to transfer the appropriate amount of currency
    function _validateERC20BalAndAllowance(
        address _tokenOwner,
        address _currency,
        uint256 _amount
    ) internal view returns (bool isValid) {
        isValid =
            IERC20(_currency).balanceOf(_tokenOwner) >= _amount &&
            IERC20(_currency).allowance(_tokenOwner, address(this)) >= _amount;
    }

    /// @dev Transfers tokens.
    function _transferOfferTokens(address _from, address _to, uint256 _quantity, IOffers.Offer memory _offer) internal {
        if (_offer.tokenType == IOffers.TokenType.ERC1155) {
            IERC1155(_offer.assetContract).safeTransferFrom(_from, _to, _offer.tokenId, _quantity, '');
        } else if (_offer.tokenType == IOffers.TokenType.ERC721) {
            IERC721(_offer.assetContract).safeTransferFrom(_from, _to, _offer.tokenId, '');
        }
    }

    function offersStorage() internal pure returns (OffersStorage storage osp) {
        bytes32 position = OFFERS_STORAGE_POSITION;
        assembly {
            osp.slot := position
        }
    }
}
