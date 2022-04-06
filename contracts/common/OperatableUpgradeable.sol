//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OperatableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) public operators;

    function __operatable_init() internal {
        __Ownable_init();
        operators[owner()] = true;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operatable: caller is not the owner");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }
}
