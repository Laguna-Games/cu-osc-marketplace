// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {IPlatformFee} from '../interfaces/IPlatformFee.sol';
import {LibEvents} from '../libraries/LibEvents.sol';
import {LibMarketplacePermissions} from '../libraries/LibMarketplacePermissions.sol';

library LibPlatformFee {
    /// @notice Position to store the storage
    bytes32 private constant MARKETPLACE_PLATFORM_FEE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('CryptoUnicorns.Marketplace.LibPlatformFee.Storage')) - 1)) &
            ~bytes32(uint256(0xff));

    struct PlatformFeeStorage {
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev Fee type variants: percentage fee and flat fee
        IPlatformFee.PlatformFeeType platformFeeType;
        /// @dev The flat amount collected by the contract as fees on primary sales.
        uint256 flatPlatformFee;
    }

    /// @dev Sets the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (_platformFeeBps > 10_000) {
            revert('Exceeds max bps');
        }
        if (_platformFeeRecipient == address(0)) {
            revert('Invalid recipient');
        }

        platformFeeStorage().platformFeeBps = uint16(_platformFeeBps);
        platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit LibEvents.PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Sets a flat fee on primary sales.
    function setupFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) internal {
        platformFeeStorage().flatPlatformFee = _flatFee;
        platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit LibEvents.FlatPlatformFeeUpdated(_platformFeeRecipient, _flatFee);
    }

    /// @dev Sets platform fee type.
    function setupPlatformFeeType(IPlatformFee.PlatformFeeType _feeType) internal {
        platformFeeStorage().platformFeeType = _feeType;

        emit LibEvents.PlatformFeeTypeUpdated(_feeType);
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function canSetPlatformFeeInfo() internal view returns (bool) {
        return LibMarketplacePermissions.hasRole(LibMarketplacePermissions.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (!canSetPlatformFeeInfo()) {
            revert('LibPlatformFee: Not authorized');
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(address _platformFeeRecipient, uint256 _flatFee) internal {
        if (!canSetPlatformFeeInfo()) {
            revert('LibPlatformFee: Not authorized');
        }

        setupFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(IPlatformFee.PlatformFeeType _feeType) internal {
        if (!canSetPlatformFeeInfo()) {
            revert('LibPlatformFee: Not authorized');
        }
        setupPlatformFeeType(_feeType);
    }

    function platformFeeStorage() internal pure returns (PlatformFeeStorage storage pfs) {
        bytes32 position = MARKETPLACE_PLATFORM_FEE_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            pfs.slot := position
        }
    }
}
