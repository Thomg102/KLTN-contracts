//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ISubjectContract.sol";
import "./interfaces/IAccessControl.sol";

contract SubjectContract is ISubjectContract, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public owner;
    Subject public subject;
    Status public status = Status.Lock;

    IAccessControl public accessControll;

    address[] public student;
    mapping(address => Student) public addressToStudent;
    mapping(address => mapping(ScoreColumn => uint256)) public score;
    uint256 public amount;
    mapping(address => bool) public completedAddress;

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

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
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

    constructor(
        address _owner,
        address _accessControll
    ) {
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
    }

    function initialize(
        address _owner,
        address _accessControll
    ) public initializer{
        require(
            owner == address(0) 
            && address(accessControll) == address(0), "Initializable: contract is already initialized");
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
    }

    function setBasicForSubject(
        string memory _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
        if (block.timestamp > _startTime) _startTime = block.timestamp;
        require(
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
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
    }

    function setScoreColumn(
        uint256 QT,
        uint256 GK,
        uint256 TH,
        uint256 CK
    ) external override {
        require(QT + GK + TH + CK == 10000, "SC: rate invalid");
        rate[ScoreColumn.QT] = QT;
        rate[ScoreColumn.GK] = GK;
        rate[ScoreColumn.TH] = TH;
        rate[ScoreColumn.CK] = CK;
    }

    function start() external override onlyOwner onlyLock {
        status = Status.Open;
    }

    function lock() external override onlyOwner onlyOpen {
        status = Status.Lock;
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
            require(
                accessControll.hasRole(keccak256("STUDENT"), _students[i]),
                "Should only add student"
            );
            _register(_students[i]);
        }
    }

    function register() external override onlyOpen onlyRoleStudent {
        _register(msg.sender);
    }

    function _register(address _student) private {
        Student storage instance = addressToStudent[_student];
        if (!instance.participantToTrue) {
            amount++;
        if (instance.studentAddress != address(0)) {
            instance.participantToTrue = true;
        } else {
            Student memory st = Student({
                studentAddress: _student,
                participantToTrue: true
            });
            addressToStudent[_student] = st;
            student.push(_student);
        }

        require(amount <= subject.maxEntrant, "Reach out limit");
        emit Register(_student);
        } 
    }

    function cancelRegister() external override onlyOpen onlyRoleStudent {
        Student storage instance = addressToStudent[msg.sender];
        require(instance.participantToTrue, "SC: cancel error");
        amount--;
        instance.participantToTrue = false;
        emit CancelRegister(msg.sender);
    }

    struct Score{
        uint256[] score;
    }

    function confirmCompletedAddress(
        address[] calldata _students, Score[] memory _score
    ) external onlyOpen onlyRoleLecturer {
        require(block.timestamp < subject.endTimeToConfirm);
        require(_students.length == _score.length);
        for (uint256 i = 0; i < _students.length; i++) {
            _register(_students[i]);
            score[_students[i]][ScoreColumn.QT] = _score[i].score[0];
            score[_students[i]][ScoreColumn.GK] = _score[i].score[1];
            score[_students[i]][ScoreColumn.TH] = _score[i].score[2];
            score[_students[i]][ScoreColumn.CK] = _score[i].score[3];
            uint256 finalScore = getFinalScore(_students[i]);
            if (finalScore >= 50000)
                completedAddress[_students[i]] = true;
        }
        emit Confirm(_students.length, block.timestamp);
    }

    function unConfirmCompletedAddress(address[] calldata _students)
        external
        onlyRoleLecturer
        onlyOpen
        override
    {
        require(
            block.timestamp > subject.endTime &&
                block.timestamp < subject.endTimeToConfirm
        );
        for (uint256 i = 0; i < _students.length; i++) {
            require(completedAddress[_students[i]], "SC: cancel error");
            completedAddress[_students[i]] = false;
        }

        emit UnConfirm(_students.length, block.timestamp);
    }

    function close() external override onlyOwner onlyOpen {
        status = Status.Close;
        require(block.timestamp > subject.endTimeToConfirm);
        emit Close(block.timestamp);
    }

    function isReadyToClose() external view returns (bool) {
        return (block.timestamp > subject.endTimeToConfirm);
    }

    function getParticipantList()
        public
        view
        onlyOpen
        returns (address[] memory)
    {
        address[] memory _student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < student.length; i++) {
            if (
                addressToStudent[student[i]].participantToTrue &&
                addressToStudent[student[i]].studentAddress != address(0)
            ) {
                _student[index] = addressToStudent[student[i]].studentAddress;
                index++;
            }
        }
        return _student;
    }

    function getParticipantListCompleted()
        public
        view
        returns (address[] memory)
    {
        address[] memory _student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < student.length; i++) {
            if (completedAddress[student[i]] && student[i] != address(0)) {
                _student[index] = student[i];
                index++;
            }
        }
        return _student;
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
                rate[ScoreColumn.CK])/10000;
    }

    function getScore(address _student) public view returns(uint256[] memory) {
        uint256[] memory list = new uint256[](5);
        list[0]=score[_student][ScoreColumn.QT];
        list[1]=score[_student][ScoreColumn.GK];
        list[2]=score[_student][ScoreColumn.TH];
        list[3]=score[_student][ScoreColumn.CK];
        list[4]=getFinalScore(_student);
        return list;
    }

    function getScoreList() public view returns(address[] memory, Score[] memory) {
        address[] memory list = getParticipantList();
        Score[] memory scoreList = new Score[](list.length);
        for (uint256 i=0; i< list.length; i++) {
            uint256[] memory _score = new uint256[](4);
            _score[0]=score[list[i]][ScoreColumn.QT];
            _score[1]=score[list[i]][ScoreColumn.GK];
            _score[2]=score[list[i]][ScoreColumn.TH];
            _score[3]=score[list[i]][ScoreColumn.CK];
            _score[4]=getFinalScore(list[i]);
            scoreList[i].score = _score;
        }
        return (list, scoreList);
    }
}
