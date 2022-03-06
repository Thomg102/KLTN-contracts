//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFactory {
    enum Object {
        Mission,
        Subject
    }

    function setObject(address mission, address subject) external;

    function getObject(Object _object) external view returns (address);

    function createNewMission(address accessControll, address rewardDistributor)
        external
        returns (address);

    function createNewSubject(address accessControll)
        external
        returns (address);
}
