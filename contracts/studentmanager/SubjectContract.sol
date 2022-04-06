//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./interfaces/ISubjectContract.sol";
import "./interfaces/IAccessControl.sol";

contract SubjectContract is ISubjectContract {
    using SafeERC20 for IERC20;
    address public immutable owner;
    Subject public subject;
    Status public status = Status.Lock;

    address public UITToken;
    IAccessControl public accessControll;

    address[] public student;
    mapping(address => Student) public addressToStudent;
    // mapping(address => mapping(ScoreColumn => uint256)) score;
    uint256 public amount;
    mapping(address => bool) public completedAddress;

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

    constructor(address _owner, address _accessControll) {
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
    }

    function setBasicForSubject(
        uint256 _subjectId,
        string memory _urlMetadata,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
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
             require(accessControll.hasRole(keccak256("STUDENT"), _students[i]), "Should only add student");
            _register(_students[i]);
        }
    }

    function register() external onlyOpen onlyRoleStudent {
        _register(msg.sender);
    }

    function _register(address _student) private {
        Student storage instance = addressToStudent[_student];
        require(!instance.participantToTrue, "SC: register error");

        amount++;
        if(instance.studentAddress != address(0)){
            instance.participantToTrue = true;
        }else{
            Student memory st = Student({
                studentAddress: _student,
                participantToTrue: true
            });
            addressToStudent[_student] = st;
            student.push(_student);
        }
        
        require(amount <= subject.maxEntrant);
    }

    function cancelRegister() external onlyOpen onlyRoleStudent {
        Student storage instance = addressToStudent[msg.sender];
        require(instance.participantToTrue, "SC: cancel error");
        amount--;
        instance.participantToTrue = false;
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
            Student memory instance = addressToStudent[_student[i]];
            require(instance.participantToTrue && instance.studentAddress == _student[i], "SC: cancel error");
            completedAddress[_student[i]] = true;
            // require(_score[i] <= 10);
            // score[_student[i]][_column] = _score[i];
        }
        emit Confirm(_student.length, block.timestamp);
    }

    function close() external override onlyOwner {
        status = Status.Close;
        require(block.timestamp>subject.endTimeToConfirm);
        emit Close(block.timestamp);
    }

    function getParticipantList() public view returns (address[] memory) {
        address[] memory _student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < student.length; i++) {
            if (addressToStudent[student[i]].participantToTrue && addressToStudent[student[i]].studentAddress !=address(0)) {
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
            if (completedAddress[student[i]] && student[i]!=address(0)) {
                _student[index] = student[i];
                index++;
            }
        }
        return _student;
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
