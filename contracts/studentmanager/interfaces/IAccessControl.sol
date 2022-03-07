// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 role;
    }
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(bytes32 indexed role, address indexed account);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleExist(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;

    function addNewRoleAdmin(bytes32 role) external;

    function removeNewRoleAdmin(bytes32 role) external;
}
