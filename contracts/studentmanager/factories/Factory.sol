//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMissionFactory.sol";
import "../interfaces/ISubjectFactory.sol";

contract Factory is Ownable {
    enum Object {
        Mission,
        Subject
    }

    mapping(Object => address) public object;

    constructor(address mission, address subject) {
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
    }

    function setObject(address mission, address subject) external {
        require(mission != address(0) && subject != address(0));
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
    }

    function getObject(Object _object) external view returns (address) {
        return object[_object];
    }

    function createNewMission() external returns (address) {
        return IMissionFactory(object[Object.Mission]).createNewMission();
    }

    function createNewSubject() external returns (address) {
        return ISubjectFactory(object[Object.Subject]).createNewMission();
    }
}
