//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITuitionContract {
    struct Tuition {
        string Id;
        string urlMetadata;
        uint256 feeByToken;
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
    event Payment(address student, uint256 timestamp, PaymentMethod _method);
    event AddStudentToTuition(uint256 studentsAmount, uint256 timestamp);
    event RemoveStudentFromTuition(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForTuition(
        string memory _tuitionId,
        string memory _urlMetadata,
        uint256 feeByToken,
        uint256 _feeByCurency,
        uint256 _startTime,
        uint256 _endTime
    ) external;

    function start() external;

    function lock() external;

    function addStudentToTuition(address[] memory _students) external;

    function removeStudentFromTuition(address[] memory _students) external;

    function paymentByToken() external;

    function paymentByCurrency(address _studentAddress) external;

    function close() external;

    function getParticipantList() external view returns (address[] memory);
}
