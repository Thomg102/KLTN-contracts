//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardDistributor {
    function addDistributorsAddress(address distributor) external;

    function removeDistributorsAddress(address distributor) external;

    function distributeReward(address account, uint256 amount) external;
}
