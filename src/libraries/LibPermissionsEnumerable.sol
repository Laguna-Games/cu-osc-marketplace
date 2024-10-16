// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */
import {LibMarketplacePermissions} from "./LibMarketplacePermissions.sol";

library LibPermissionsEnumerable {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 private constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION = keccak256(
        abi.encode(uint256(keccak256("CryptoUnicorns.Marketplace.LibPermissionsEnumerable.Storage")) - 1)
    ) & ~bytes32(uint256(0xff));

    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct PermissionsEnumerableStorage {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRoleEnumerable(bytes32 role, address account) internal {
        LibMarketplacePermissions._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRoleEnumerbale(bytes32 role, address account) internal {
        LibMarketplacePermissions._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].index;
        LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].index += 1;

        LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].members[idx] = account;
        LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].indexOf[account];

        delete LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].members[idx];
        delete LibPermissionsEnumerable.permissionsEnumerableStorage().roleMembers[role].indexOf[account];
    }

    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) internal view returns (address member) {
        uint256 currentIndex = permissionsEnumerableStorage().roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = permissionsEnumerableStorage().roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (
                LibMarketplacePermissions.hasRole(role, address(0))
                    && i == permissionsEnumerableStorage().roleMembers[role].indexOf[address(0)]
            ) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) internal view returns (uint256 count) {
        uint256 currentIndex = permissionsEnumerableStorage().roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (LibMarketplacePermissions.hasRole(role, address(0))) {
            count += 1;
        }
    }

    function permissionsEnumerableStorage() internal pure returns (PermissionsEnumerableStorage storage pes) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            pes.slot := position
        }
    }
}
