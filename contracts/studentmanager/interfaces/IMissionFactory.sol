// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMissionFactory {
    function createNewMission(
        address _accessControll,
        address _rewardDistributor
    ) external returns (address);
}
