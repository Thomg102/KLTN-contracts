//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMissionFactory.sol";
import "../interfaces/ISubjectFactory.sol";
import "../interfaces/IScholarshipFactory.sol";
import "../interfaces/ITuitionFactory.sol";
import "../interfaces/IFactory.sol";

contract Factory is Ownable, IFactory {
    mapping(Object => address) public object;

    constructor(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) {
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
        object[Object.Scholarship] = scholarship;
        object[Object.Tuition] = tuition;
    }

    function setObject(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) external override {
        require(
            mission != address(0) &&
                subject != address(0) &&
                scholarship != address(0) &&
                tuition != address(0)
        );
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
        object[Object.Scholarship] = scholarship;
        object[Object.Tuition] = tuition;
    }

    function getObject(Object _object) external view returns (address) {
        return object[_object];
    }

    function createNewMission(address accessControll, address rewardDistributor)
        external
        override
        returns (address)
    {
        return
            IMissionFactory(object[Object.Mission]).createNewMission(
                accessControll,
                rewardDistributor
            );
    }

    function createNewSubject(address accessControll)
        external
        override
        returns (address)
    {
        return
            ISubjectFactory(object[Object.Subject]).createNewMission(
                accessControll
            );
    }

    function createNewScholarship(
        address accessControll,
        address rewardDistributor
    ) external override returns (address) {
        return
            IScholarshipFactory(object[Object.Scholarship])
                .createNewScholarship(accessControll, rewardDistributor);
    }

    function createNewTuition(address accessControll, address rewardDistributor)
        external
        override
        returns (address)
    {
        return
            ITuitionFactory(object[Object.Tuition]).createNewTuition(
                accessControll,
                rewardDistributor
            );
    }
}
