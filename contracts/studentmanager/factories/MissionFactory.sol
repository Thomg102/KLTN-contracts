// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../MissionContract.sol";
import "../interfaces/IMissionFactory.sol";

contract MissionFactory is IMissionFactory {
    function createNewMission(
        address owner,
        address _accessControll,
        address _rewardDistributor
    ) public override returns (address) {
        MissionContract missionContract = new MissionContract(
            owner,
            _accessControll,
            _rewardDistributor
        );
        return address(missionContract);
    }
}
