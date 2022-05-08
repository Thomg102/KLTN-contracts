//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISubjectContract {
    struct Subject {
        uint256 Id;
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

    event CreatedNewSubject(uint256 indexed id);
    event Confirm(uint256 studentslength, uint256 timestamp);
    event UnConfirm(address student, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForSubject(
        uint256 _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external;

    function start() external;

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

    function unConfirmCompletedAddress(address _student) external;

    function close() external;
}
