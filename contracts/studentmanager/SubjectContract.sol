//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISubjectContract.sol";
import "./interfaces/IAccessControl.sol";

contract SubjectContract is ISubjectContract, Ownable {
    using SafeERC20 for IERC20;
    Subject public subject;
    Status public status = Status.Lock;

    address public UITToken;
    IAccessControl public accessControll;

    Student[] public student;
    mapping(address => uint256) addressToStudentIndex;
    // mapping(address => mapping(ScoreColumn => uint256)) score;
    uint256 public amount;
    // mapping(address => bool) public completedAddress;

    // mapping(ScoreColumn => uint256) public rate;
    // ti le diem, giua ki, cuoi ki, qua trinh

    modifier onlyLock() {
        require(status == Status.Lock, "SC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "SC: Only Open");
        _;
    }

    modifier onlyRoleLecturer() {
        require(
            accessControll.hasRole(keccak256("LECTURER"), msg.sender),
            "MC: Only Lecturer"
        );
        _;
    }

    modifier onlyRoleStudent() {
        require(
            accessControll.hasRole(keccak256("STUDENT"), msg.sender),
            "MC: Only Student"
        );
        _;
    }

    constructor(address _accessControll) {
        accessControll = IAccessControl(_accessControll);
    }

    function setBasicForSubject(
        uint256 _subjectId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
        require(_award > 0, "SC: Award should greater than Zero");
        require(
            block.timestamp < _startTime &&
                _startTime < _endTimeToRegister &&
                _endTimeToRegister < _endTime &&
                _endTime < _endTimeToConfirm,
            "SC: Time is invalid"
        );

        subject = Subject(
            _subjectId,
            _urlMetadata,
            _maxEntrant,
            _persionInCharge,
            _award,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
    }

    // function setScoreColumn(
    //     uint256 QT,
    //     uint256 GK,
    //     uint256 TH,
    //     uint256 CK
    // ) external override onlyOwner {
    //     require(QT + GK + TH + CK == 10000, "SC: rate invalid");
    //     rate[ScoreColumn.QT] = QT;
    //     rate[ScoreColumn.GK] = GK;
    //     rate[ScoreColumn.TH] = TH;
    //     rate[ScoreColumn.CK] = CK;
    // }

    function start() external override onlyOwner {
        status = Status.Open;
    }

    function addStudentToSubject(address[] calldata _students)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            msg.sender == subject.personInCharge,
            "MC: Only the person in charge"
        );
        for (uint256 i = 0; i < _students.length; i++) {
            _register(_students[i]);
        }
        require(amount <= subject.maxEntrant);
    }

    function register() external onlyOpen onlyRoleStudent {
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

    function cancelRegister() external onlyOpen onlyRoleStudent {
        uint256 index = addressToStudentIndex[msg.sender];
        require(student[index].participantToTrue, "SC: cancel error");
        amount--;
        student[index].participantToTrue = false;
    }

    function confirmCompletedAddress(
        address[] calldata _student // uint256[] calldata _score,// ScoreColumn _column
    ) external override onlyOpen onlyRoleLecturer {
        require(
            block.timestamp > subject.endTime &&
                block.timestamp < subject.endTimeToConfirm
        );
        // require(_student.length == _score.length);
        for (uint256 i = 0; i < _student.length; i++) {
            uint256 index = addressToStudentIndex[_student[i]];
            require(student[index].participantToTrue, "SC: cancel error");
            // require(_score[i] <= 10);
            // score[_student[i]][_column] = _score[i];
        }
        emit Confirm(_student.length, block.timestamp);
    }

    function close() external override onlyOwner {
        status = Status.Close;
        emit Close(block.timestamp);
    }

    // function getFinalScore(address _student) public view returns (uint256) {
    //     return
    //         (score[_student][ScoreColumn.QT] *
    //             rate[ScoreColumn.QT] +
    //             score[_student][ScoreColumn.GK] *
    //             rate[ScoreColumn.GK] +
    //             score[_student][ScoreColumn.TH] *
    //             rate[ScoreColumn.TH] +
    //             score[_student][ScoreColumn.CK] *
    //             rate[ScoreColumn.CK]) / 10000;
    // }
}
