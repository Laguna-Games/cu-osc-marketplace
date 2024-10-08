// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import {Address} from '../libraries/Address.sol';

library LibInitializer {
    /// @custom:storage-location erc7201:init.storage
    /// @dev storage slot for the entrypoint contract's storage.
    bytes32 internal constant INIT_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('CryptoUnicorns.Marketplace.Storage')) - 1)) & ~bytes32(uint256(0xff));

    /// @dev Layout of the entrypoint contract's storage.
    struct InitStorage {
        uint8 initialized;
        bool initializing;
    }

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    function onlyInitializing() internal view {
        require(initStorage().initializing, 'Initializable: contract is not initializing');
    }

    function preInitialize() internal {
        InitStorage storage _init = initStorage();

        // Ensure the contract hasn't been initialized or is not in the process of initializing
        bool isTopLevelCall = !_init.initializing;
        require((isTopLevelCall && _init.initialized < 1), 'Initializable: contract is already initialized');

        // Set the initializing flag to prevent reentrancy
        if (isTopLevelCall) {
            _init.initializing = true;
        }

        // Set the initialized state to prevent initialization from running again
        _init.initialized = 1;
    }

    function postInitialize() internal {
        InitStorage storage _init = initStorage();

        // Only perform these actions if this was the top level call to initialize
        if (_init.initializing) {
            _init.initializing = false;
            emit Initialized(1);
        }
    }

    function preReinitialize(uint8 version) internal {
        InitStorage storage _init = initStorage();

        // Ensure the contract is not already initializing, and the requested version is greater
        require(!_init.initializing && _init.initialized < version, 'Initializable: contract is already initialized');

        // Set the new initialized version and initializing flag
        _init.initialized = version;
        _init.initializing = true;
    }

    function postReinitialize(uint8 version) internal {
        InitStorage storage _init = initStorage();

        // Ensure this is the end of the top level call to reinitialize
        require(_init.initializing, 'Initializable: contract is not initializing');

        // Unset the initializing flag and emit the event
        _init.initializing = false;
        emit Initialized(version);
    }

    function disableInitializers() internal {
        uint8 _initialized = initStorage().initialized;
        bool _initializing = initStorage().initializing;

        require(!_initializing, 'Initializable: contract is initializing');
        if (_initialized < type(uint8).max) {
            initStorage().initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /// @dev Returns the entrypoint contract's data at the relevant storage location.
    function initStorage() internal pure returns (InitStorage storage ins) {
        bytes32 position = INIT_STORAGE_POSITION;
        assembly {
            ins.slot := position
        }
    }
}
