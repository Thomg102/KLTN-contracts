// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITuitionFactory {
    function createNewTuition(
        address owner,
        address _accessControll,
        address _rewardDistributor
    ) external returns (address);
}
