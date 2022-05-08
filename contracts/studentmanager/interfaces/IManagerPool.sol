//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IManagerPool {

    function addStudentInfo(string memory hashInfo) external;

    function addLecturerInfo(address lecturerAddr, string memory hashInfo)
        external;

    function createNewMission(
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function createNewSubject(
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function createNewScholarship(
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function createNewTuition(
        string memory _urlMetadata,
        uint256 _feeByToken,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function close(address pool) external;
}
