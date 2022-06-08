//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IScholarshipContract {
    struct Scholarship {
        string Id;
        string urlMetadata;
        uint256 award;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    enum PaymentMethod {
        Token,
        Currency
    }

    event CreatedNewTuition(uint256 indexed id);
    event AddStudentToScholarship(uint256 studentsAmount, uint256 timestamp);
    event RemoveStudentFromScholarship(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForScholarship(
        string memory _scholarshipId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function start() external;

    function lock() external;

    function addStudentToScholarship(address[] memory _students) external;

    function removeStudentFromScholarship(address[] memory _students) external;

    function close() external;

    function getParticipantList() external view returns (address[] memory);
}
