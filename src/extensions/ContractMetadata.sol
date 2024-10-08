// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {LibContractMetadata} from '../libraries/LibContractMetadata.sol';

/**
 *  @author  thirdweb.com
 *
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */
abstract contract ContractMetadata {
    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external {
        LibContractMetadata._setupContractURI(_uri);
    }

    /// @notice Returns the contract metadata URI.
    function contractURI() public view returns (string memory) {
        return LibContractMetadata.contractMetadataStorage().contractURI;
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function canSetContractURI() public view returns (bool) {
        return LibContractMetadata._canSetContractURI();
    }
}
