//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFactory {
    enum Object {
        Mission,
        Subject,
        Scholarship,
        Tuition
    }

    function setObject(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) external;

    function getObject(Object _object) external view returns (address);

    function createNewMission(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);

    function createNewSubject(address owner, address accessControll)
        external
        returns (address);

    function createNewScholarship(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);

    function createNewTuition(
        address _owner,
        address accessControll,
        address rewardDistributor
    ) external returns (address);
}
