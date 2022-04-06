// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISubjectFactory {
    function createNewMission(address owner,address _accessControll)
        external
        returns (address);
}
