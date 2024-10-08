// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//  ==========  Internal imports    ==========

import {LibContractMetadata} from "../../libraries/LibContractMetadata.sol";
import {LibMarketplacePermissions} from "../../libraries/LibMarketplacePermissions.sol";
import {LibPlatformFee} from "../../libraries/LibPlatformFee.sol";
import {LibContractOwner} from "../../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibInitializer} from "../../libraries/LibInitializer.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {LibMarketplace} from "../../libraries/LibMarketplace.sol";

contract MarketplaceV3Facet is IERC721Receiver {
    /// @dev Initializes the contract, like a constructor.
    function initMarketplace(
        address _defaultAdmin,
        string memory _contractURI,
        address _platformFeeRecipient,
        uint16 _platformFeeBps,
        address _nativeTokenWrapper
    ) external {
        LibContractOwner.enforceIsContractOwner(); // Ensure that the contract owner is enforced.
        LibInitializer.preInitialize();

        LibMarketplacePermissions._setupRole(
            LibMarketplacePermissions.DEFAULT_ADMIN_ROLE,
            _defaultAdmin
        );
        LibMarketplacePermissions._setupRole(
            LibMarketplacePermissions.EXTENSION_ROLE,
            _defaultAdmin
        );
        LibMarketplacePermissions._setupRole(
            keccak256("LISTER_ROLE"),
            address(0)
        );
        LibMarketplacePermissions._setupRole(
            keccak256("ASSET_ROLE"),
            address(0)
        );

        LibMarketplacePermissions._setupRole(
            LibMarketplacePermissions.EXTENSION_ROLE,
            _defaultAdmin
        );
        LibMarketplacePermissions._setRoleAdmin(
            LibMarketplacePermissions.EXTENSION_ROLE,
            LibMarketplacePermissions.EXTENSION_ROLE
        );

        // Initialize this contract's state.
        LibContractMetadata._setupContractURI(_contractURI);
        LibPlatformFee._setupPlatformFeeInfo(
            _platformFeeRecipient,
            _platformFeeBps
        );
        LibMarketplace.setNativeTokenWrapper(_nativeTokenWrapper);
        LibInitializer.postInitialize();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // implement ERC1155Receiver.onERC1155Received
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function setNativeTokenWrapper(address _nativeTokenWrapper) external {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplace.setNativeTokenWrapper(_nativeTokenWrapper);
    }

    function getNativeTokenWrapper() external view returns (address) {
        return LibMarketplace.nativeTokenWrapper();
    }

    function addCurrency(address _currency) external {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplace.addCurrency(_currency);
    }

    function removeCurrency(address _currency) external {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplace.removeCurrency(_currency);
    }

    function currencies() external view returns (address[] memory) {
        return LibMarketplace.currencies();
    }

    function currencyIndex(address _currency) external view returns (uint256) {
        return LibMarketplace.currencyIndex(_currency);
    }
}
