// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {LibEvents} from "./LibEvents.sol";
import {LibMarketplacePermissions} from "./LibMarketplacePermissions.sol";

library LibContractMetadata {
    /// @custom:storage-location erc7201:contract.metadata.storage
    /// @dev storage slot for the contract metadata.
    bytes32 internal constant CONTRACT_METADATA_STORAGE_POSITION = keccak256(
        abi.encode(uint256(keccak256("CryptoUnicorns.Marketplace.LibContractMetadata.Storage")) - 1)
    ) & ~bytes32(uint256(0xff));

    struct ContractMetadataStorage {
        /// @notice Returns the contract metadata URI.
        string contractURI;
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        if (!_canSetContractURI()) {
            revert("LibContractMetadata: Not authorized");
        }
        string memory prevURI = contractMetadataStorage().contractURI;
        contractMetadataStorage().contractURI = _uri;

        emit LibEvents.ContractURIUpdated(prevURI, _uri);
    }

    function _canSetContractURI() internal view returns (bool) {
        return LibMarketplacePermissions.hasRole(LibMarketplacePermissions.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns the ContractMetadataStorage.
    function contractMetadataStorage() internal pure returns (ContractMetadataStorage storage cms) {
        bytes32 position = CONTRACT_METADATA_STORAGE_POSITION;
        assembly {
            cms.slot := position
        }
    }
}
