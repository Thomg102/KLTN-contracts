//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IScholarshipContract.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";

contract ScholarshipContract is IScholarshipContract, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public owner;
    Scholarship public scholarship;
    Status public status = Status.Lock;

    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;

    address[] public participants;
    uint256 public amount;
    mapping(address => bool) public addressIsExist;
    mapping(address => bool) public completedAddress;
    mapping(address => bool) public participantToTrue;

    modifier onlyLock() {
        require(status == Status.Lock, "SC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "SC: Only Open");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyRoleLecturer() {
        require(
            accessControll.hasRole(keccak256("LECTURER"), msg.sender),
            "SC: Only Lecturer"
        );
        _;
    }

    modifier onlyRoleAdmin() {
        require(
            accessControll.hasRole(keccak256("ADMIN"), msg.sender) ||
                accessControll.hasRole(keccak256("LECTURER"), msg.sender),
            "SC: Only Lecturer or Admin"
        );
        _;
    }

    modifier onlyRoleStudent() {
        require(
            accessControll.hasRole(keccak256("STUDENT"), msg.sender),
            "SC: Only Student"
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

    function initialize(
        address _owner,
        address _accessControll,
        address _rewardDistributor
    ) public initializer{
        require(
            owner == address(0) 
            && address(accessControll) == address(0) 
            && address(rewardDistributor) == address(0), "Initializable: contract is already initialized");
        owner = _owner;
        accessControll = IAccessControl(_accessControll);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
    }

    function setBasicForScholarship(
        string memory _scholarshipId,
        string memory _urlMetadata,
        uint256 _award,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _endTimeToRegister,
        uint256 _endTimeToConfirm
    ) external override onlyOwner onlyLock {
        require(_award > 0, "SC: Award should greater than Zero");
        if (block.timestamp > _startTime) _startTime = block.timestamp;
        require(
                _startTime < _endTimeToRegister &&
                _endTimeToRegister < _endTime &&
                _endTime < _endTimeToConfirm,
            "MS: Time is invalid"
        );

        scholarship = Scholarship(
            _scholarshipId,
            _urlMetadata,
            _award,
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

    function lock() external override onlyOwner onlyOpen {
        status = Status.Lock;
    }

    function addStudentToScholarship(address[] calldata _students)
        external
        override
        onlyRoleAdmin
        onlyOpen
    {
        require(
            msg.sender == scholarship.persionInCharge,
            "SC: Only the person in charge"
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
            block.timestamp <= scholarship.endTimeToRegister,
            "Expired time to register"
        );
        require(!participantToTrue[_student], "SC: register error");
        amount++;
        if (!addressIsExist[_student]) {
            participants.push(_student);
        }
        addressIsExist[_student] = true;
        participantToTrue[_student] = true;
        emit Register(_student);
    }

    function cancelRegister() external override onlyRoleStudent onlyOpen {
        require(participantToTrue[msg.sender], "SC: cancel error");
        amount--;
        participantToTrue[msg.sender] = false;
        emit CancelRegister(msg.sender);
    }

    function confirmCompletedAddress(address[] calldata _students)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            block.timestamp > scholarship.endTime &&
                block.timestamp < scholarship.endTimeToConfirm
        );
        for (uint256 i = 0; i < _students.length; i++) {
            require(participantToTrue[_students[i]], "MS: confirm error");
            completedAddress[_students[i]] = true;
        }
        emit Confirm(_students.length, block.timestamp);
    }

    function unConfirmCompletedAddress(address[] calldata _students)
        external
        override
        onlyRoleLecturer
        onlyOpen
    {
        require(
            block.timestamp > scholarship.endTime &&
                block.timestamp < scholarship.endTimeToConfirm
        );
        for (uint256 i = 0; i < _students.length; i++) {
            require(completedAddress[_students[i]], "MS: confirm error");
            completedAddress[_students[i]] = false;
        }

        emit UnConfirm(_students.length, block.timestamp);
    }

    function close() external override onlyOwner onlyOpen {
        require(block.timestamp > scholarship.endTimeToConfirm);
        status = Status.Close;
        address[] memory student = getParticipantListCompleted();
        for (uint256 i = 0; i < student.length; i++) {
            if (student[i] != address(0))
                rewardDistributor.distributeReward(student[i], scholarship.award);
        }
        emit Close(block.timestamp);
    }

    function isReadyToClose() onlyOpen external view returns(bool) {
        return (block.timestamp > scholarship.endTime);
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
