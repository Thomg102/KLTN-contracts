//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISubjectContract {
    struct Subject {
        uint256 Id;
        string urlMetadata;
        uint256 award;
        uint256 startTime;
        uint256 endTime;
        uint256 distanceConfirm;
        uint256 limitAmount;
        address creator;
        address lecturer;
    }

    enum ScoreColumn {
        QT,
        GK,
        TH,
        CK
    }

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
    event Close(uint256 timestamp);

    function setBasicForSubject(
        uint256 _subjectId,
        string calldata _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _distanceConfirm,
        uint256 _limitAmount,
        address _creator,
        address _lecturer
    ) external;

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external;

    function addStudentToSubject(address[] memory _students) external;

    function confirmCompletedAddress(
        address[] calldata _student,
        uint256[] calldata _score,
        ScoreColumn _column
    ) external;

    function distributeReward() external;

    function withdraw(address _tokenAddress, uint256 _amount) external;
}
