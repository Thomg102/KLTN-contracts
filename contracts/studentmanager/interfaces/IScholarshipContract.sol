//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IScholarshipContract {
    struct Scholarship {
        string Id;
        string urlMetadata;
        uint256 award;
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

    event CreatedNewTuition(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event AddStudentToScholarship(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForScholarship(
        string memory _scholarshipId,
        string memory _urlMetadata,
        uint256 _award,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function lock() external;

    function register() external;

    function cancelRegister() external;

    function addStudentToScholarship(address[] memory _students) external;

    function confirmCompletedAddress(address[] memory _students) external;

    function unConfirmCompletedAddress(address[] memory _students) external;

    function close() external;

    function getParticipantListCompleted()
        external
        view
        returns (address[] memory);
}
