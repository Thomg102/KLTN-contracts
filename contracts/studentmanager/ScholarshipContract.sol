//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./interfaces/IScholarshipContract.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";

contract ScholarshipContract is IScholarshipContract {
    using SafeERC20 for IERC20;
    address public immutable owner;
    Scholarship public scholarship;
    Status public status = Status.Lock;

    address public UITToken;
    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;

    address[] private participants;
    mapping(address => uint256) public participantToIndex;
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

    modifier onlyRoleAdmin() {
        require(
            accessControll.hasRole(keccak256("ADMIN"), msg.sender),
            "SC: Only Lecturer"
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

    function setBasicForScholarship(
        uint256 _scholarshipId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external override onlyOwner onlyLock {
        require(_award > 0, "SC: Award should greater than Zero");
        require(
            block.timestamp < _startTime && _startTime < _endTime,
            "SC: Time is invalid"
        );

        scholarship = Scholarship(
            _scholarshipId,
            _urlMetadata,
            _award,
            _startTime,
            _endTime
        );
    }

    function start() external override onlyOwner onlyLock {
        status = Status.Open;
    }

    function addStudentToScholarship(address[] calldata _students)
        external
        override
        onlyRoleAdmin
        onlyOpen
    {
        for (uint256 i = 0; i < _students.length; i++) {
            participants.push(_students[i]);
            participantToIndex[_students[i]] = participants.length - 1;
        }
    }

    function removeStudentFromScholarship(address _student)
        external
        onlyRoleAdmin
    {
        uint256 index = participantToIndex[_student];
        delete participants[index];
    }

    function close() external override onlyOwner {
        status = Status.Close;
        (address[] memory student, uint256 amount) = getParticipantList();
        for (uint256 i = 0; i < amount; i++) {
            rewardDistributor.distributeReward(student[i], scholarship.award);
        }
        emit Close(block.timestamp);
    }

    function getParticipantList()
        public
        view
        override
        returns (address[] memory, uint256)
    {
        address[] memory student = new address[](participants.length);
        uint256 index;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participantToTrue[participants[i]] && participants[i] != address(0)) {
                student[index] = participants[i];
                index++;
            }
        }
        return (student, index);
    }
}
