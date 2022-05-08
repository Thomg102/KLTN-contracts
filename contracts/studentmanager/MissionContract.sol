//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./interfaces/IMissionContract.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";

contract MissionContract is IMissionContract {
    using SafeERC20 for IERC20;
    address public immutable owner;
    Mission public mission;
    Status public status = Status.Lock;

    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;

    address[] public participants;
    uint256 public amount;
    mapping(address => bool) public addressIsExist;
    mapping(address => bool) public participantToTrue;
    mapping(address => bool) public completedAddress;

    modifier onlyLock() {
        require(status == Status.Lock, "MC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "MC: Only Open");
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
        address _accessControll,
        address _rewardDistributor
    ) {
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
    }

    function setBasicForMission(
        uint256 _missionId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
        require(_award > 0, "MC: Award should greater than Zero");
        require(
            block.timestamp < _startTime &&
                _startTime < _endTimeToRegister &&
                _endTimeToRegister < _endTime &&
                _endTime < _endTimeToConfirm,
            "MC: Time is invalid"
        );

        mission = Mission(
            _missionId,
            _urlMetadata,
            _award,
            _maxEntrant,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
    }

    function start() external override onlyOwner onlyLock {
        status = Status.Open;
    }

    function addStudentToMission(address[] calldata _students)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            msg.sender == mission.persionInCharge,
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

    function register() external override onlyRoleStudent onlyOpen {
        _register(msg.sender);
    }

    function _register(address _student) private {
        require(
            block.timestamp <= mission.endTimeToRegister,
            "Expired time to register"
        );
        require(!participantToTrue[_student], "MS: register error");
        amount++;
        if (!addressIsExist[_student]) {
            participants.push(_student);
        }
        addressIsExist[_student] = true;
        participantToTrue[_student] = true;
        require(amount <= mission.maxEntrant);
    }

    function cancelRegister() external override onlyRoleStudent onlyOpen {
        require(participantToTrue[msg.sender], "MS: cancel error");
        amount--;
        participantToTrue[msg.sender] = false;
    }

    function confirmCompletedAddress(address[] calldata _student)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            block.timestamp > mission.endTime &&
                block.timestamp < mission.endTimeToConfirm
        );
        for (uint256 i = 0; i < _student.length; i++) {
            require(participantToTrue[_student[i]], "MS: cancel error");
            completedAddress[_student[i]] = true;
        }
        emit Confirm(_student.length, block.timestamp);
    }

    function unConfirmCompletedAddress(address _student)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            block.timestamp > mission.endTime &&
                block.timestamp < mission.endTimeToConfirm
        );

        require(completedAddress[_student], "MS: cancel error");
        completedAddress[_student] = false;
        emit UnConfirm(_student, block.timestamp);
    }

    function close() external override onlyOwner {
        require(block.timestamp > mission.endTimeToConfirm);
        status = Status.Close;
        address[] memory student = getParticipantListCompleted();
        for (uint256 i = 0; i < student.length; i++) {
            if (student[i] != address(0))
                rewardDistributor.distributeReward(student[i], mission.award);
        }
        emit Close(block.timestamp);
    }

    function getParticipantList() public view returns (address[] memory) {
        address[] memory student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participantToTrue[participants[i]]) {
                student[index] = participants[i];
                index++;
            }
        }
        return student;
    }

    function getParticipantListCompleted()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < participants.length; i++) {
            if (completedAddress[participants[i]]) {
                student[index] = participants[i];
                index++;
            }
        }
        return student;
    }
}
