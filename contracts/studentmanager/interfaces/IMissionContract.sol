//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
import "./IManagerPool.sol";

interface IMissionContract is IManagerPool {
    struct Mission {
        string Id;
        string urlMetadata;
        uint256 award;
        uint256 maxEntrant;
        address persionInCharge;
        uint256 startTime;
        uint256 endTimeToRegister;
        uint256 endTime;
        uint256 endTimeToConfirm;
        RewardType rewardType;
        uint256 nftId;
    }

    enum Status {
        Lock,
        Open,
        Close
    }

    event CreatedNewMission(uint256 indexed id);
    event Register(address _student);
    event CancelRegister(address _student);
    event Confirm(uint256 studentsAmount, uint256 timestamp);
    event UnConfirm(uint256 studentsAmount, uint256 timestamp);
    event Close(uint256 timestamp);

    function setBasicForMission(
        string memory _missionId,
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm,
        RewardType _rewardType,
        uint256 _nftId
    ) external;

    function start() external;
    
    function lock() external;

    function addStudentToMission(address[] memory _students) external;

    function register() external;

    function cancelRegister() external;

    function confirmCompletedAddress(address[] memory _students) external;

    function unConfirmCompletedAddress(address[] memory _students) external;

    function close() external;

    function getParticipantListCompleted()
        external
        view
        returns (address[] memory);

    function setUITNFTAddress(address _UITNFT) external;
}
