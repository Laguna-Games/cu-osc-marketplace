// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import {LibMarketplacePermissions} from "../libraries/LibMarketplacePermissions.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

/**
 *  @title   PermissionsFacet
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */
contract MarketplacePermissionsFacet {
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return LibMarketplacePermissions.hasRole(role, account);
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(
        bytes32 role,
        address account
    ) public view returns (bool) {
        return LibMarketplacePermissions.hasRoleWithSwitch(role, account);
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return LibMarketplacePermissions.getRoleAdmin(role);
    }

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplacePermissions.grantRole(role, account);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplacePermissions.revokeRole(role, account);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public {
        LibContractOwner.enforceIsContractOwner();
        LibMarketplacePermissions.renounceRole(role, account);
    }

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function isAuthorizedCallToUpgrade() public view returns (bool) {
        return
            LibMarketplacePermissions.hasRole(
                LibMarketplacePermissions.EXTENSION_ROLE,
                msg.sender
            );
    }
}
