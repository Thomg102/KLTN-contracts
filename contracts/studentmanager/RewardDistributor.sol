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
        distributors[msg.sender] = true;
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

    function setManagerPoolPermission(address _managerPool) external onlyOwner {
        require(_managerPool != address(0));
        managerPool = _managerPool;
    }

    function addDistributorsAddress(address distributor)
        external
        override
        onlyPermission
    {
        distributors[distributor] = true;
    }

    function removeDistributorsAddress(address distributor)
        external
        override
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

    function getTotalBalance() public view returns(uint256){
        return IERC20(UITToken).balanceOf(address(this));
    }

    function getUITTokenAddress()public override view returns(address){
        return address(UITToken);
    }
}
