//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMissionContract {
    struct Mission {
        uint256 Id;
        string urlMetadata;
        uint256 award;
        uint256 maxEntrant;
        address persionInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(address student, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForMission(
        uint256 _missionId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function addStudentToMission(address[] memory _students) external;

    function confirmCompletedAddress(address[] memory _student) external;

    function unConfirmCompletedAddress(address _student) external;

    function close() external;

    function getParticipantListCompleted()
        external
        view
        returns (address[] memory);
}
