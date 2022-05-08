//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./interfaces/ITuitionContract.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";

contract TuitionContract is ITuitionContract {
    using SafeERC20 for IERC20;

    address public immutable owner;
    Tuition public tuition;
    Status public status = Status.Lock;

    IAccessControl public accessControll;
    address public rewardDistributor;

    address[] public participants;
    uint256 public amount;
    mapping(address => uint256) public participantToIndex;
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
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyRoleAdmin() {
        require(
            accessControll.hasRole(keccak256("ADMIN"), msg.sender),
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
        rewardDistributor = _rewardDistributor;
    }

    function setBasicForTuition(
        uint256 _tuitionId,
        string memory _urlMetadata,
        uint256 _feeByToken,
        uint256 _startTime,
        uint256 _endTime
    ) external override onlyOwner onlyLock {
        require(_feeByToken > 0, "MC: Award should greater than Zero");
        require(
            block.timestamp < _startTime && _startTime < _endTime,
            "MC: Time is invalid"
        );

        tuition = Tuition(
            _tuitionId,
            _urlMetadata,
            _feeByToken,
            _startTime,
            _endTime
        );
    }

    function start() external override onlyOwner onlyLock {
        status = Status.Open;
    }

    function addStudentToTuition(address[] calldata _students)
        external
        override
        onlyRoleAdmin
        onlyOpen
    {
        for (uint256 i = 0; i < _students.length; i++) {
            require(
                accessControll.hasRole(keccak256("STUDENT"), _students[i]),
                "Should only add student"
            );
            require(!participantToTrue[_students[i]], "Added");
            participants.push(_students[i]);
            participantToIndex[_students[i]] = participants.length - 1;
            participantToTrue[_students[i]] = true;
            amount++;
        }
    }

    function removeStudentFromTuition(address _student)
        external
        override
        onlyRoleAdmin
    {
        require(participantToTrue[_student], "Error when remove");
        uint256 index = participantToIndex[_student];
        amount--;
        participantToTrue[_student] = false;
        delete participants[index];
    }

    function paymentByToken() external override onlyRoleStudent {
        require(participantToTrue[msg.sender], "TC: You are not in list");
        require(!completedAddress[msg.sender], "TC: You paid tuition");
        address UITToken = IRewardDistributor(rewardDistributor)
            .getUITTokenAddress();
        IERC20(UITToken).safeTransferFrom(
            msg.sender,
            rewardDistributor,
            tuition.feeByToken
        );
        completedAddress[msg.sender] = true;
        emit Payment(msg.sender, block.timestamp, PaymentMethod.Token);
    }

    function paymentByCurrency() external override onlyRoleAdmin {
        require(participantToTrue[msg.sender], "TC: You are not in list");
        require(!completedAddress[msg.sender], "TC: You paid tuition");
        completedAddress[msg.sender] = true;
        emit Payment(msg.sender, block.timestamp, PaymentMethod.Currency);
    }

    function close() external override onlyOwner {
        status = Status.Close;
        require(block.timestamp > tuition.endTime);
        emit Close(block.timestamp);
    }

    function getParticipantList()
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory student = new address[](amount);
        uint256 index;
        for (uint256 i = 0; i < participants.length; i++) {
            if (
                participantToTrue[participants[i]] &&
                participants[i] != address(0)
            ) {
                student[index] = participants[i];
                index++;
            }
        }
        return student;
    }

    function getParticipantListCompleted()
        public
        view
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
