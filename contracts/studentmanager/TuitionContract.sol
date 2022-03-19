//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITuitionContract.sol";
import "./interfaces/IAccessControl.sol";

contract TuitionContract is ITuitionContract, Ownable {
    using SafeERC20 for IERC20;
    Tuition public tuition;
    Status public status = Status.Lock;

    address public UITToken;
    IAccessControl public accessControll;
    address public rewardDistributor;

    address[] private participants;
    uint256 public amount;
    mapping(address => uint256) public participantToIndex;
    mapping(address => bool) public participantToTrue;

    modifier onlyLock() {
        require(status == Status.Lock, "MC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "MC: Only Open");
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

    constructor(address _accessControll, address _rewardDistributor) {
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
            participants.push(_students[i]);
            participantToIndex[_students[i]] = participants.length - 1;
        }
    }

    function removeStudentFromTuition(address _student) external onlyRoleAdmin {
        uint256 index = participantToIndex[_student];
        delete participants[index];
    }

    function paymentByToken() external override onlyRoleStudent {
        require(!participantToTrue[msg.sender], "TC: You paid tuition");
        IERC20(UITToken).safeTransferFrom(
            msg.sender,
            rewardDistributor,
            tuition.feeByToken
        );
        participantToTrue[msg.sender] = true;
        emit Payment(msg.sender, block.timestamp, PaymentMethod.Token);
    }

    function paymentByCurrency(address student) external override onlyRoleAdmin {
        require(!participantToTrue[student], "TC: Student paid tuition");
        participantToTrue[msg.sender] = true;
        emit Payment(student, block.timestamp, PaymentMethod.Currency);
    }

    function close() external override onlyOwner {
        status = Status.Close;
        emit Close(block.timestamp);
    }

    function getParticipantList() public view returns (address[] memory) {
        address[] memory student = new address[](participants.length);
        uint256 index;
        for (uint256 i = 0; i < participants.length; i++) {
            if (participantToTrue[participants[i]]) {
                require(participants[i] != address(0));
                student[index] = participants[i];
                index++;
            }
        }
        return student;
    }
}
