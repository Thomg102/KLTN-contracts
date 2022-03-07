//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMissionContract.sol";
import "./interfaces/ISubjectContract.sol";
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
        Subject
    }

    IFactory public factory;
    IAccessControl public accessControll;
    IRewardDistributor public rewardDistributor;
    Object[] public pools;
    mapping(address => bool) public existed;
    Counters.Counter public idCountMission;
    Counters.Counter public idCountSubject;

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

    function setFactory(address _factory) public onlyOwner {
        factory = IFactory(_factory);
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
        rewardDistributor.addDistributorsAddress(subjectContract);
    }

    function removeDistributor(address pool) public onlyRoleAdmin {
        require(existed[pool]);
        //if status = Lose
        rewardDistributor.removeDistributorsAddress(pool);
    }
}
