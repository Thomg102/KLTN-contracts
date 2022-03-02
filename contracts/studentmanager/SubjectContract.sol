//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISubjectContract.sol";

contract SubjectContract is ISubjectContract, Ownable {
    using SafeERC20 for IERC20;
    Subject public subject;
    Status public status = Status.Lock;

    address public UITToken;

    Student[] public student;
    mapping(address => uint256) addressToStudentIndex;
    mapping(address => mapping(ScoreColumn => uint256)) score;
    uint256 public amount;
    uint256 private gapTimeToStart = 86400;
    // mapping(address => bool) public completedAddress;

    mapping(ScoreColumn => uint256) public rate;
    // ti le diem, giua ki, cuoi ki, qua trinh

    modifier onlyLock() {
        require(status == Status.Lock, "SC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "SC: Only Open");
        _;
    }

    function setBasicForSubject(
        uint256 _subjectId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _distanceConfirm,
        uint256 _limitAmount,
        address _creator,
        address _lecturer
    ) external override onlyOwner onlyLock {
        require(_award > 0, "SC: Award should greater than Zero");
        require(
            _startTime < _endTime &&
                block.timestamp + gapTimeToStart < _startTime,
            "SC: Time is invalid"
        );

        subject = Subject(
            _subjectId,
            _urlMetadata,
            _award,
            _startTime,
            _endTime,
            _distanceConfirm,
            _limitAmount,
            _creator,
            _lecturer
        );
    }

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external override onlyOwner {
        require(QT + GK + TH + CK == 10000, "SC: rate invalid");
        rate[ScoreColumn.QT] = QT;
        rate[ScoreColumn.GK] = GK;
        rate[ScoreColumn.TH] = TH;
        rate[ScoreColumn.CK] = CK;
    }

    function start() external onlyOwner {
        status = Status.Open;
    }

    function addStudentToSubject(address[] calldata _students)
        external
        override
        onlyOwner
        onlyOpen
    {
        amount += _students.length;
        for (uint256 i = 0; i < _students.length; i++) {
            _register(_students[i]);
        }
    }

    function register() external onlyOpen {
        _register(msg.sender);
    }

    function _register(address _student) private {
        uint256 index = addressToStudentIndex[_student];
        require(!student[index].participantToTrue, "SC: register error");
        amount++;
        Student memory st = Student({
            studentAddress: _student,
            participantToTrue: true
        });
        student.push(st);
        addressToStudentIndex[_student] = student.length - 1;
    }

    function cancelRegister() external onlyOpen {
        uint256 index = addressToStudentIndex[msg.sender];
        require(student[index].participantToTrue, "SC: cancel error");
        amount--;
        student[index].participantToTrue = false;
    }

    function confirmCompletedAddress(
        address[] calldata _student,
        uint256[] calldata _score,
        ScoreColumn _column
    ) external override onlyOpen {
        require(
            block.timestamp < subject.endTime + subject.distanceConfirm &&
                block.timestamp > subject.endTime
        );
        require(_student.length == _score.length);
        for (uint256 i = 0; i < _student.length; i++) {
            uint256 index = addressToStudentIndex[_student[i]];
            require(student[index].participantToTrue, "SC: cancel error");
            require(_score[i] <= 10);
            score[_student[i]][_column] = _score[i];
        }
        emit Confirm(_student.length, block.timestamp);
    }

    function distributeReward() external override {
        address[] memory completedStudent;
        require(block.timestamp > subject.endTime + subject.distanceConfirm);
        uint256 index = 0;
        for (uint256 i = 0; i < student.length; i++) {
            require(student[i].participantToTrue, "SC: cancel error");
            uint256 finalScore = getFinalScore(student[i].studentAddress);
            if (finalScore > 8) {
                completedStudent[index] = student[i].studentAddress;
                index++;
            }
        }
        uint256 award = subject.award / index;
        for (uint256 i = 0; i < index; i++) {
            uint256 balance = getTotalToken(UITToken);
            balance > award
                ? IERC20(UITToken).safeTransfer(completedStudent[i], award)
                : IERC20(UITToken).safeTransfer(completedStudent[i], balance);
        }

        emit Close(block.timestamp);
    }

    function getFinalScore(address _student) public view returns (uint256) {
        return
            (score[_student][ScoreColumn.QT] *
                rate[ScoreColumn.QT] +
                score[_student][ScoreColumn.GK] *
                rate[ScoreColumn.GK] +
                score[_student][ScoreColumn.TH] *
                rate[ScoreColumn.TH] +
                score[_student][ScoreColumn.CK] *
                rate[ScoreColumn.CK]) / 10000;
    }

    function getTotalToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {}
}
