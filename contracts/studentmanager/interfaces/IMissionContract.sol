//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMissionContract {
    struct Mission {
        uint256 Id;
        string urlMetadata;
        uint256 award;
        uint256 startTime;
        uint256 endTime;
        uint256 distanceConfirm;
        address[] participants;
        mapping(address => bool) participantToTrue;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Confirm(address[] students, uint256 timestamp);

    function setBasicForMission(
        string calldata _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function addStudentToMission(
        address[] calldata _students,
        uint256 _missionId
    ) external;

    function confirmCompletedAddress(
        address[] calldata _student,
        bool _isCompelted
    ) external;

    function distributeReward() external;

    function withdraw(address _tokenAddress, uint256 _amount) external;
}
