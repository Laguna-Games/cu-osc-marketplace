// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {LibRoyalty} from "../libraries/LibRoyalty.sol";
import {LibMarketplacePermissions} from "../libraries/LibMarketplacePermissions.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
/**
 *
 *  @title   Royalty Facet
 *  @notice  Thirdweb's `Royalty` is a contract extension to be used with a marketplace contract.
 *           It exposes functions for fetching royalty settings for a token.
 *           It Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.
 */

contract RoyaltyFacet {
    // add access control
    function setRoyaltyEngineAddress(
        address _royaltyEngineAddress
    ) public virtual {
        LibContractOwner.enforceIsContractOwner();
        canSetRoyaltyEngine();
        LibRoyalty.setRoyaltyEngineAddress(_royaltyEngineAddress);
    }

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory recipients, uint256[] memory amounts)
    {
        return LibRoyalty.getRoyalty(tokenAddress, tokenId, value);
    }

    /// @dev Returns original or overridden address for RoyaltyEngineV1
    function getRoyaltyEngineAddress()
        public
        view
        returns (address royaltyEngineAddress)
    {
        return LibRoyalty.getRoyaltyEngineAddress();
    }

    /// @dev Returns whether royalty engine address can be set in the given execution context.
    function canSetRoyaltyEngine() public view returns (bool) {
        return
            LibMarketplacePermissions.hasRole(
                LibMarketplacePermissions.DEFAULT_ADMIN_ROLE,
                msg.sender
            );
    }
}
