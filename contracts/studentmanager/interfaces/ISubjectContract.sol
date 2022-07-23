//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ISubjectContract {
    struct Subject {
        string Id;
        string urlMetadata;
        uint256 maxEntrant;
        address personInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
    }

    // enum ScoreColumn {
    //     QT,
    //     GK,
    //     TH,
    //     CK
    // }

    struct Student {
        address studentAddress;
        bool participantToTrue;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForSubject(
        string memory _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

    function lock() external;

    // function setScoreColumn(
    //     uint256 QT,
    //     uint256 GK,
    //     uint256 TH,
    //     uint256 CK
    // ) external;

    function addStudentToSubject(address[] memory _students) external;

    function register() external;

    function cancelRegister() external;

    function confirmCompletedAddress(
        address[] calldata _student
        // uint256[] calldata _score,
        // ScoreColumn _column
    ) external;

    function unConfirmCompletedAddress(address[] calldata _students) external;

    function close() external;
}
