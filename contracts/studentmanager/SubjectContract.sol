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
    uint256 public amount;
    uint256 private gapTimeToStart = 86400;
    mapping(address => bool) public completedAddress;

    mapping(Rate => uint256) public rate;
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

    function setRate(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external override onlyOwner {
        require(QT + GK + TH + CK == 10000, "SC: rate invalid");
        rate[Rate.QT] = QT;
        rate[Rate.GK] = GK;
        rate[Rate.TH] = TH;
        rate[Rate.CK] = CK;
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
        student.push(Student(_student, 0, true));
        addressToStudentIndex[_student] = student.length - 1;
    }

    function cancelRegister() external onlyOpen {
        uint256 index = addressToStudentIndex[msg.sender];
        require(student[index].participantToTrue, "SC: cancel error");
        amount--;
        student[index].participantToTrue = false;
    }

    function confirmCompletedAddress(Student[] calldata _student)
        external
        override
        onlyOpen
    {
        require(
            block.timestamp < subject.endTime + subject.distanceConfirm &&
                block.timestamp > subject.endTime
        );
        for (uint256 i = 0; i < _student.length; i++) {
            uint256 index = addressToStudentIndex[_student[i].studentAddress];
            require(student[index].participantToTrue, "SC: cancel error");
            student[index].score = student[i].score;
        }
        emit Confirm(_student.length, block.timestamp);
    }

    // function distributeReward() external override {
    //     //chia thuong  theo diem trung binh
    //     address[] memory completedStudent;
    //     uint256 award = missions.award / amount;
    //     require(block.timestamp > missions.endTime + missions.distanceConfirm);
    //     for (uint256 i = 0; i < participants.length; i++) {
    //         uint256 balance = getTotalToken(UITToken);
    //         if (participantToTrue[participants[i]]) {
    //             balance > award
    //                 ? IERC20(UITToken).safeTransfer(participants[i], award)
    //                 : IERC20(UITToken).safeTransfer(participants[i], balance);
    //         }
    //     }

    //     emit Close(block.timestamp);
    // }

    function getTotalToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {}
}
