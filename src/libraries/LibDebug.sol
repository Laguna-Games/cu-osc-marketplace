// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library LibDebug {
    /// @dev storage slot for the debug storage.
    bytes32 internal constant DEBUG_STORAGE_POSITION = keccak256(
        abi.encode(uint256(keccak256("CryptoUnicorns.Marketplace.LibDebug.Storage")) - 1)
    ) & ~bytes32(uint256(0xff));

    struct DebugStorage {
        uint256 counter;
    }

    function debugStorage() internal pure returns (DebugStorage storage ds) {
        bytes32 position = DEBUG_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function debugInc() internal {
        debugStorage().counter++;
    }
}
