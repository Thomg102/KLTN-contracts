//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable UITToken;
    mapping(address => bool) public distributors;
    address public managerPool;

    constructor(IERC20 _UITToken, address _managerPool) {
        UITToken = _UITToken;
        managerPool = _managerPool;
    }

    modifier onlyDistributor() {
        require(distributors[msg.sender], "RD: Only distributor");
        _;
    }

    modifier onlyPermission() {
        require(
            msg.sender == owner() || msg.sender == managerPool,
            "RD: Only permission"
        );
        _;
    }

    function addDistributorsAddress(address distributor)
        external
        onlyPermission
    {
        distributors[distributor] = true;
    }

    function removeDistributorsAddress(address distributor)
        external
        onlyPermission
    {
        distributors[distributor] = false;
    }

    function distributeReward(address account, uint256 amount)
        external
        override
        onlyDistributor
    {
        UITToken.safeTransfer(account, amount);
    }
}
