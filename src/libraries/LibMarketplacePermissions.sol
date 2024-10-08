// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Strings} from "../libraries/Strings.sol";
import {LibEvents} from "./LibEvents.sol";

library LibMarketplacePermissions {
    /// @custom:storage-location erc7201:permissions.storage
    /// @dev storage slot for the permissions storage.
    bytes32 internal constant PERMISSIONS_STORAGE_POSITION = keccak256(
        abi.encode(uint256(keccak256("CryptoUnicorns.Marketplace.LibMarketplacePermissions.Storage")) - 1)
    ) & ~bytes32(uint256(0xff));

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 internal constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @dev Only EXTENSION_ROLE holders can perform upgrades.
    bytes32 internal constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");
    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 internal constant MAX_BPS = 10_000;

    struct PermissionsStorage {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return permissionsStorage()._hasRole[role][account];
    }

    function hasRoleWithSwitch(bytes32 role, address account) internal view returns (bool) {
        if (!permissionsStorage()._hasRole[role][address(0)]) {
            return permissionsStorage()._hasRole[role][account];
        }

        return true;
    }

    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return permissionsStorage()._getRoleAdmin[role];
    }

    function grantRole(bytes32 role, address account) internal {
        _checkRole(LibMarketplacePermissions.permissionsStorage()._getRoleAdmin[role], msg.sender);
        if (LibMarketplacePermissions.permissionsStorage()._hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    function revokeRole(bytes32 role, address account) internal {
        _checkRole(LibMarketplacePermissions.permissionsStorage()._getRoleAdmin[role], msg.sender);
        _revokeRole(role, account);
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view {
        if (!LibMarketplacePermissions.permissionsStorage()._hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function renounceRole(bytes32 role, address account) internal {
        if (msg.sender != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = LibMarketplacePermissions.permissionsStorage()._getRoleAdmin[role];
        LibMarketplacePermissions.permissionsStorage()._getRoleAdmin[role] = adminRole;
        emit LibEvents.RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal {
        LibMarketplacePermissions.permissionsStorage()._hasRole[role][account] = true;
        emit LibEvents.RoleGranted(role, account, msg.sender);
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal {
        _checkRole(role, account);
        delete LibMarketplacePermissions.permissionsStorage()._hasRole[role][account];
        emit LibEvents.RoleRevoked(role, account, msg.sender);
    }

    /// @dev Checks whether the caller has ASSET_ROLE.
    function onlyAssetRole(address _asset) internal view {
        require(LibMarketplacePermissions.hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
    }

    /// @dev Checks whether the caller has DEFAULT_ADMIN_ROLE.
    function onlyDefaultAdminRole() internal view {
        require(LibMarketplacePermissions.hasRoleWithSwitch(DEFAULT_ADMIN_ROLE, msg.sender), "!DEFAULT_ADMIN_ROLE");
    }

    function permissionsStorage() internal pure returns (PermissionsStorage storage psp) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            psp.slot := position
        }
    }
}
