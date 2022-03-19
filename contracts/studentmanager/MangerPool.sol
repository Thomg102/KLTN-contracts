//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionContract.sol";
import "./interfaces/ISubjectContract.sol";
import "./interfaces/IScholarshipContract.sol";
import "./interfaces/ITuitionContract.sol";
import "./interfaces/IGeneralContract.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAccessControl.sol";
import "./interfaces/IRewardDistributor.sol";

contract ManagerPool is Ownable {
    using Counters for Counters.Counter;

    struct Object {
        address objectAddress;
        Type tipe;
    }
    enum Type {
        Mission,
        Subject,
        Scholarship,
        Tuition
    }

    IFactory public factory;
    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;
    Object[] public pools;
    mapping(address => bool) public existed;
    Counters.Counter public idCountMission;
    Counters.Counter public idCountSubject;
    Counters.Counter public idCountScholarship;
    Counters.Counter public idCountTuition;

    mapping(address => string) public studentInfo;
    mapping(address => string) public lecturerInfo;

    constructor(
        address _factory,
        address _accessControll,
        address _rewardDistributor
    ) {
        factory = IFactory(_factory);
        accessControll = IAccessControl(_accessControll);
        rewardDistributor = IRewardDistributor(_rewardDistributor);
    }

    modifier onlyRoleAdmin() {
        require(
            accessControll.hasRole(keccak256("ADMIN"), msg.sender),
            "MP: Only Admin"
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

    function setFactory(address _factory) public onlyOwner {
        factory = IFactory(_factory);
    }

    function addStudentInfo(string memory hashInfo) public onlyRoleStudent {
        studentInfo[msg.sender] = hashInfo;
    }

    function addLecturerInfo(address lecturerAddr, string memory hashInfo)
        public
        onlyRoleAdmin
    {
        lecturerInfo[lecturerAddr] = hashInfo;
    }

    function createNewMission(
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external onlyRoleAdmin {
        address missionContract = factory.createNewMission(
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(missionContract, Type.Mission));
        existed[missionContract] = true;
        uint256 _missionId = idCountMission.current();
        idCountMission.increment();
        IMissionContract(missionContract).setBasicForMission(
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
        IMissionContract(missionContract).start();
        rewardDistributor.addDistributorsAddress(missionContract);
    }

    function createNewSubject(
        string memory _urlMetadata,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external onlyRoleAdmin {
        address subjectContract = factory.createNewSubject(
            address(accessControll)
        );
        pools.push(Object(subjectContract, Type.Subject));
        existed[subjectContract] = true;
        uint256 _subjectId = idCountSubject.current();
        idCountSubject.increment();
        ISubjectContract(subjectContract).setBasicForSubject(
            _subjectId,
            _urlMetadata,
            _award,
            _maxEntrant,
            _persionInCharge,
            _startTime,
            _endTimeToRegister,
            _endTime,
            _endTimeToConfirm
        );
        // ISubjectContract(subjectContract).setScoreColumn(qt, gk, th, ck);
        ISubjectContract(subjectContract).start();
        // rewardDistributor.addDistributorsAddress(subjectContract);
    }

    function createNewScholarship(
        string memory _urlMetadata,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRoleAdmin {
        address scholarshipContract = factory.createNewScholarship(
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(scholarshipContract, Type.Scholarship));
        existed[scholarshipContract] = true;
        uint256 _scholarshipId = idCountScholarship.current();
        idCountScholarship.increment();
        IScholarshipContract(scholarshipContract).setBasicForScholarship(
            _scholarshipId,
            _urlMetadata,
            _award,
            _startTime,
            _endTime
        );
        IScholarshipContract(scholarshipContract).start();
        rewardDistributor.addDistributorsAddress(scholarshipContract);
    }

    function createNewTuition(
        string memory _urlMetadata,
        uint256 _feeByToken,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRoleAdmin {
        address tuitionContract = factory.createNewTuition(
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(tuitionContract, Type.Tuition));
        existed[tuitionContract] = true;
        uint256 _tuitionId = idCountTuition.current();
        idCountTuition.increment();
        ITuitionContract(tuitionContract).setBasicForTuition(
            _tuitionId,
            _urlMetadata,
            _feeByToken,
            _startTime,
            _endTime
        );
        ITuitionContract(tuitionContract).start();
        rewardDistributor.addDistributorsAddress(tuitionContract);
    }

    function close(address pool) external onlyRoleAdmin {
        IGeneralContract(pool).close();
        _removeDistributor(pool);
    }

    function _removeDistributor(address pool) private onlyRoleAdmin {
        require(existed[pool]);
        rewardDistributor.removeDistributorsAddress(pool);
    }
}
