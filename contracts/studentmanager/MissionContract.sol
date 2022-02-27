//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionContract.sol";

contract MissionContract is IMissionContract, Ownable {
    using SafeERC20 for IERC20;
    Mission public missions;
    Status public status = Status.Lock;

    address public UITToken;

    address[] private participants;
    uint256 public amount;
    mapping(address => bool) public participantToTrue;
    uint256 private gapTimeToStart = 86400;
    mapping(address => bool) public completedAddress;
    bool public isConfirmed;

    modifier onlyLock() {
        require(status == Status.Lock, "MC: Only Lock");
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open, "MC: Only Open");
        _;
    }

    function setBasicForMission(
        uint256 _missionId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _distanceConfirm
    ) external override onlyOwner onlyLock {
        require(_award > 0, "MC: Award should greater than Zero");
        require(
            _startTime < _endTime &&
                block.timestamp + gapTimeToStart < _startTime,
            "MC: Time is invalid"
        );

        missions = Mission(
            _missionId,
            _urlMetadata,
            _award,
            _startTime,
            _endTime,
            _distanceConfirm
        );
    }

    function start() external onlyOwner {
        status = Status.Open;
    }

    function addStudentToMission(address[] calldata _students)
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
        require(!participantToTrue[_student], "MS: register error");
        amount++;
        participants.push(_student);
        participantToTrue[_student] = true;
    }

    function cancelRegister() external onlyOpen {
        require(participantToTrue[msg.sender], "MS: cancel error");
        amount--;
        participantToTrue[msg.sender] = false;
    }

    function confirmCompletedAddress(address[] calldata _student)
        external
        override
        onlyOpen
    {
        require(
            block.timestamp < missions.endTime + missions.distanceConfirm &&
                block.timestamp > missions.endTime
        );
        require(!isConfirmed);
        for (uint256 i = 0; i < _student.length; i++) {
            require(participantToTrue[_student[i]], "MS: cancel error");
            completedAddress[_student[i]] = true;
        }
        isConfirmed = true;
        amount = _student.length;
        emit Confirm(_student.length, block.timestamp);
    }

    function distributeReward() external override {
        address[] memory completedStudent;
        uint256 award = missions.award / amount;
        if (!isConfirmed) {
            require(
                block.timestamp > missions.endTime + missions.distanceConfirm
            );
            for (uint256 i = 0; i < participants.length; i++) {
                uint256 balance = getTotalToken(UITToken);
                if (participantToTrue[participants[i]]) {
                    balance > award
                        ? IERC20(UITToken).safeTransfer(participants[i], award)
                        : IERC20(UITToken).safeTransfer(
                            participants[i],
                            balance
                        );
                }
            }
        } else {
            // for (uint256 i = 0; i < amount; i++) {
            //     uint256 balance = getTotalToken(UITToken);
            //     if (participantToTrue) {
            //         balance > award
            //             ? IERC20(UITToken).safeTransfer(participants[i], award)
            //             : IERC20(UITToken).safeTransfer(
            //                 participants[i],
            //                 balance
            //             );
            //     }
            // }
        }
    }

    function getTotalToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {}
}
