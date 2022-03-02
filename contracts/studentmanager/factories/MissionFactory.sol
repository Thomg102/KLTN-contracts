// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../MissionContract.sol";
import "../interfaces/IMissionFactory.sol";

contract MissionFactory is IMissionFactory {
    function createNewMission() public override returns (address) {
        MissionContract missionContract = new MissionContract();
        return address(missionContract);
    }
}
