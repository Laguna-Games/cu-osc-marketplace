// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import {IPlatformFee} from "../interfaces/IPlatformFee.sol";
import {LibPlatformFee} from "../libraries/LibPlatformFee.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

/**
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */
contract PlatformFeeFacet {
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo()
        public
        view
        virtual
        returns (address, uint16)
    {
        return (
            LibPlatformFee.platformFeeStorage().platformFeeRecipient,
            uint16(LibPlatformFee.platformFeeStorage().platformFeeBps)
        );
    }

    /// @dev Returns the platform fee bps and recipient.
    function getFlatPlatformFeeInfo()
        public
        view
        virtual
        returns (address, uint256)
    {
        return (
            LibPlatformFee.platformFeeStorage().platformFeeRecipient,
            LibPlatformFee.platformFeeStorage().flatPlatformFee
        );
    }

    /// @dev Returns the platform fee type.
    function getPlatformFeeType()
        public
        view
        virtual
        returns (IPlatformFee.PlatformFeeType)
    {
        return LibPlatformFee.platformFeeStorage().platformFeeType;
    }

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _platformFeeBps
    ) external virtual {
        LibContractOwner.enforceIsContractOwner();
        LibPlatformFee.setPlatformFeeInfo(
            _platformFeeRecipient,
            _platformFeeBps
        );
    }

    /// @notice Lets a module admin set a flat fee on primary sales.
    function setFlatPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _flatFee
    ) external virtual {
        LibContractOwner.enforceIsContractOwner();
        LibPlatformFee.setFlatPlatformFeeInfo(_platformFeeRecipient, _flatFee);
    }

    /// @notice Lets a module admin set platform fee type.
    function setPlatformFeeType(
        IPlatformFee.PlatformFeeType _feeType
    ) external virtual {
        LibContractOwner.enforceIsContractOwner();
        LibPlatformFee.setPlatformFeeType(_feeType);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function canSetPlatformFeeInfo() public view virtual returns (bool) {
        return LibPlatformFee.canSetPlatformFeeInfo();
    }
}
