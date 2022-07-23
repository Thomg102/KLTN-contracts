//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMissionFactory.sol";
import "../interfaces/ISubjectFactory.sol";
import "../interfaces/IScholarshipFactory.sol";
import "../interfaces/ITuitionFactory.sol";
import "../interfaces/IFactory.sol";
import "./MyProxy.sol";

contract FactoryProxy is Ownable, IFactory {
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

    function getObject(Object _object) external override view returns (address) {
        return object[_object];
    }

    function createNewMission(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external override returns (address) {
        return 
        _createProxy(
            object[Object.Mission], 
            owner, 
            accessControll, 
            rewardDistributor);
    }

    function createNewSubject(address owner, address accessControll)
        external
        override
        returns (address)
    {
        bytes4 initializeSelector = bytes4(keccak256("initialize(address,address)"));
        bytes memory data = abi.encodeWithSelector(
            initializeSelector, 
            owner,
            accessControll);
        MyProxy proxy = new MyProxy(object[Object.Subject], data);
        return address(proxy);
    }

    function createNewScholarship(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external override returns (address) {
        return 
        _createProxy(
            object[Object.Scholarship], 
            owner, 
            accessControll, 
            rewardDistributor);   
    }

    function createNewTuition(
        address owner,
        address accessControll,
        address rewardDistributor
    ) external override returns (address) {
        return 
        _createProxy(
            object[Object.Tuition], 
            owner, 
            accessControll, 
            rewardDistributor);
    }

    function _createProxy(
        address _implementation, 
        address owner, 
        address accessControll,
        address rewardDistributor
    ) private returns(address) {
        bytes4 initializeSelector = bytes4(keccak256("initialize(address,address,address)"));
        bytes memory data = abi.encodeWithSelector(
            initializeSelector, 
            owner,
            accessControll,
            rewardDistributor);
        MyProxy proxy = new MyProxy(_implementation, data);
        return address(proxy);
    }

    function upgradeTo(address payable _competitionAddress, address _newImplementation, bytes memory data, bool _forceCall) external onlyOwner{
        MyProxy(_competitionAddress).upgradeToAndCall(_newImplementation, data, _forceCall);
    }
}
