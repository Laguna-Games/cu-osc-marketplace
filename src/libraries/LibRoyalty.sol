// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb
import {IRoyalty, IERC2981} from "../interfaces/IRoyalty.sol";
import {IRoyaltyPayments} from "../interfaces/IRoyaltyPayments.sol";
import {IRoyaltyEngineV1} from "../interfaces/IRoyaltyEngineV1.sol";
import {LibEvents} from "../libraries/LibEvents.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {console} from "../../lib/forge-std/src/console.sol";

library LibRoyalty {
    /// @custom:storage-location erc7201:royalty.payments.storage
    /// @dev storage slot for the royalty payments storage.
    bytes32 private constant ROYALTY_STORAGE_POSITION =
        keccak256(
            abi.encode(
                uint256(
                    keccak256("CryptoUnicorns.Marketplace.LibRoyalty.Storage")
                ) - 1
            )
        ) & ~bytes32(uint256(0xff));

    struct RoyaltyStorage {
        /// @dev The (default) address that receives all royalty value.
        address royaltyRecipient;
        /// @dev The (default) % of a sale to take as royalty (in basis points).
        uint16 royaltyBps;
        /// @dev Token ID => royalty recipient and bps for token
        mapping(uint256 => IRoyalty.RoyaltyInfo) royaltyInfoForToken;
        // @dev Address of the royalty engine contract
        address royaltyEngineAddress;
    }

    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        internal
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        address royaltyEngineAddress = getRoyaltyEngineAddress();

        if (royaltyEngineAddress == address(0)) {
            try IERC2981(tokenAddress).royaltyInfo(tokenId, value) returns (
                address recipient,
                uint256 amount
            ) {
                require(amount <= value, "Invalid royalty amount");

                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
            } catch {}
        } else {
            (recipients, amounts) = IRoyaltyEngineV1(royaltyEngineAddress)
                .getRoyalty(tokenAddress, tokenId, value);
        }
    }

    /// @dev Lets a contract admin update the royalty engine address
    function setRoyaltyEngineAddress(address _royaltyEngineAddress) internal {
        // add access control
        address currentAddress = royaltyStorage().royaltyEngineAddress;
        royaltyStorage().royaltyEngineAddress = _royaltyEngineAddress;
        emit LibEvents.RoyaltyEngineUpdated(
            currentAddress,
            _royaltyEngineAddress
        );
    }

    /// @dev Returns original or overridden address for RoyaltyEngineV1
    function getRoyaltyEngineAddress()
        internal
        view
        returns (address royaltyEngineAddress)
    {
        return royaltyStorage().royaltyEngineAddress;
    }

    /**
     *  @notice   View royalty info for a given token and sale price.
     *  @dev      Returns royalty amount and recipient for `tokenId` and `salePrice`.
     *  @param tokenId          The tokenID of the NFT for which to query royalty info.
     *  @param salePrice        Sale price of the token.
     *
     *  @return receiver        Address of royalty recipient account.
     *  @return royaltyAmount   Royalty amount calculated at current royaltyBps value.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address receiver, uint256 royaltyAmount) {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / 10_000;
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(
        uint256 _tokenId
    ) internal view returns (address, uint16) {
        IRoyalty.RoyaltyInfo memory royaltyForToken = royaltyStorage()
            .royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (
                    royaltyStorage().royaltyRecipient,
                    uint16(royaltyStorage().royaltyBps)
                )
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *  @notice Returns the defualt royalty recipient and BPS for this contract's NFTs.
     */
    function getDefaultRoyaltyInfo() internal view returns (address, uint16) {
        return (
            royaltyStorage().royaltyRecipient,
            uint16(royaltyStorage().royaltyBps)
        );
    }

    /**
     *  @notice         Updates default royalty recipient and bps.
     *  @dev            Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {DefaultRoyalty Event}; See {_setupDefaultRoyaltyInfo}.
     *
     *  @param _royaltyRecipient   Address to be set as default royalty recipient.
     *  @param _royaltyBps         Updated royalty bps.
     */
    function setDefaultRoyaltyInfo(
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) internal {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyStorage().royaltyRecipient = _royaltyRecipient;
        royaltyStorage().royaltyBps = uint16(_royaltyBps);

        emit LibEvents.DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /**
     *  @notice         Updates default royalty recipient and bps for a particular token.
     *  @dev            Sets royalty info for `_tokenId`. Caller should be authorized to set royalty info.
     *                  See {_canSetRoyaltyInfo}.
     *                  Emits {RoyaltyForToken Event}; See {_setupRoyaltyInfoForToken}.
     *
     *  @param _recipient   Address to be set as royalty recipient for given token Id.
     *  @param _bps         Updated royalty bps for the token Id.
     */
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (!_canSetRoyaltyInfo()) {
            revert("Not authorized");
        }

        _setupRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setupRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) internal {
        if (_bps > 10_000) {
            revert("Exceeds max bps");
        }

        royaltyStorage().royaltyInfoForToken[_tokenId] = IRoyalty.RoyaltyInfo({
            recipient: _recipient,
            bps: _bps
        });

        emit LibEvents.RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view returns (bool) {
        return msg.sender == LibContractOwner.contractOwner();
    }

    function royaltyStorage()
        internal
        pure
        returns (RoyaltyStorage storage rss)
    {
        bytes32 position = ROYALTY_STORAGE_POSITION;
        assembly {
            rss.slot := position
        }
    }
}
