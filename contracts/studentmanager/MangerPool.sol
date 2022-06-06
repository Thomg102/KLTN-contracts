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

    event AddStudentInfo(address studentAddr, string hashInfo);
    event UpdateStudentInfo(address studentAddr, string hashInfo);
    event AddLecturerInfo(address lecturerAddr, string hashInfo);
    event NewMission(string _urlMetadata);
    event NewScholarship(string _urlMetadata);
    event NewSubject(string _urlMetadata);
    event NewTuition(string _urlMetadata);
    event TuitionLocked(address[] _listTuitions);
    event SubjectLocked(address[] _listSubjects);
    event MissionLocked(address[] _listMissions);
    event ScholarshipLocked(address[] _listScholarships);
    event StudentRoleRevoked(address[] studentAddrs);
    event LecturerRoleRevoked(address[] lecturerAddrs);

    function setFactory(address _factory) public onlyOwner {
        factory = IFactory(_factory);
    }

    function addStudentInfo(address studentAddr, string memory hashInfo)
        public
        onlyRoleAdmin
    {
        studentInfo[studentAddr] = hashInfo;
        accessControll.grantRole(keccak256("STUDENT"), studentAddr);
        emit AddStudentInfo(studentAddr, hashInfo);
    }

    function revokeStudentRole(address[] memory studentAddrs)
        public
        onlyRoleAdmin
    {
        for (uint i = 0; i < studentAddrs.length; i++) {
            accessControll.revokeRole(keccak256("STUDENT"), studentAddrs[i]);
        }

        emit StudentRoleRevoked(studentAddrs);
    }

    function update(address studentAdress, string memory hash)
        public
        onlyRoleStudent
    {
        require(studentAdress == msg.sender, "You are not allowed");
        require(
            keccak256(abi.encodePacked((studentInfo[msg.sender]))) !=
                keccak256(abi.encodePacked((hash))),
            "You did not edit"
        );
        studentInfo[msg.sender] = hash;
        emit UpdateStudentInfo(studentAdress, hash);
    }

    function addLecturerInfo(address lecturerAddr, string memory hashInfo)
        public
        onlyRoleAdmin
    {
        lecturerInfo[lecturerAddr] = hashInfo;
        accessControll.grantRole(keccak256("LECTURER"), lecturerAddr);
        emit AddLecturerInfo(lecturerAddr, hashInfo);
    }

    function revokeLecturerRole(address[] memory lecturerAddrs)
        public
        onlyRoleAdmin
    {
        for (uint i = 0; i < lecturerAddrs.length; i++) {
            accessControll.revokeRole(keccak256("LECTURER"), lecturerAddrs[i]);
        }

        emit LecturerRoleRevoked(lecturerAddrs);
    }

    function createNewMission(
        string memory _urlMetadata,
        string memory _missionId,
        uint256 _award,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external onlyRoleAdmin {
        address missionContract = factory.createNewMission(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(missionContract, Type.Mission));
        existed[missionContract] = true;
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
        emit NewMission(_urlMetadata);
    }

    function createNewSubject(
        string memory _urlMetadata,
        string memory _subjectId,
        uint256 _maxEntrant,
        address _persionInCharge,
        uint256 _startTime,
        uint256 _endTimeToRegister,
        uint256 _endTime,
        uint256 _endTimeToConfirm
    ) external onlyRoleAdmin {
        address subjectContract = factory.createNewSubject(
            address(this),
            address(accessControll)
        );
        pools.push(Object(subjectContract, Type.Subject));
        existed[subjectContract] = true;
        ISubjectContract(subjectContract).setBasicForSubject(
            _subjectId,
            _urlMetadata,
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
        emit NewSubject(_urlMetadata);
    }

    function createNewScholarship(
        string memory _urlMetadata,
        string memory _scholarshipId,
        uint256 _award,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRoleAdmin {
        address scholarshipContract = factory.createNewScholarship(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(scholarshipContract, Type.Scholarship));
        existed[scholarshipContract] = true;
        IScholarshipContract(scholarshipContract).setBasicForScholarship(
            _scholarshipId,
            _urlMetadata,
            _award,
            _startTime,
            _endTime
        );
        IScholarshipContract(scholarshipContract).start();
        rewardDistributor.addDistributorsAddress(scholarshipContract);
        emit NewScholarship(_urlMetadata);
    }

    function createNewTuition(
        string memory _urlMetadata,
        string memory _tuitionId,
        uint256 _feeByToken,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRoleAdmin {
        address tuitionContract = factory.createNewTuition(
            address(this),
            address(accessControll),
            address(rewardDistributor)
        );
        pools.push(Object(tuitionContract, Type.Tuition));
        existed[tuitionContract] = true;
        ITuitionContract(tuitionContract).setBasicForTuition(
            _tuitionId,
            _urlMetadata,
            _feeByToken,
            _startTime,
            _endTime
        );
        ITuitionContract(tuitionContract).start();
        rewardDistributor.addDistributorsAddress(tuitionContract);
        emit NewTuition(_urlMetadata);
    }

    function close(address pool) external onlyRoleAdmin {
        IGeneralContract(pool).close();
        _removeDistributor(pool);
    }

    function _removeDistributor(address pool) private onlyRoleAdmin {
        require(existed[pool]);
        rewardDistributor.removeDistributorsAddress(pool);
    }

    function lockTuition(address[] memory _listTuitions) external onlyRoleAdmin {
        for (uint i = 0; i < _listTuitions.length; i++) {
            require(existed[_listTuitions[i]]);
            ITuitionContract(_listTuitions[i]).lock();
        }
        emit TuitionLocked(_listTuitions);
    }

    function lockSubject(address[] memory _listSubjects) external onlyRoleAdmin {
        for (uint i = 0; i < _listSubjects.length; i++) {
            require(existed[_listSubjects[i]]);
            ISubjectContract(_listSubjects[i]).lock();
        }
        emit SubjectLocked(_listSubjects);
    }

    function lockScholarship(address[] memory _listScholarships) external onlyRoleAdmin {
        for (uint i = 0; i < _listScholarships.length; i++) {
            require(existed[_listScholarships[i]]);
            IScholarshipContract(_listScholarships[i]).lock();
        }
        emit ScholarshipLocked(_listScholarships);
    }

    function lockMission(address[] memory _listMissions) external onlyRoleAdmin {
        for (uint i = 0; i < _listMissions.length; i++) {
            require(existed[_listMissions[i]]);
            IMissionContract(_listMissions[i]).lock();
        }
        emit MissionLocked(_listMissions);
    }
}
