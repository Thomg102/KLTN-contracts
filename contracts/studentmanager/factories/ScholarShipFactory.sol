// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../ScholarshipContract.sol";
import "../interfaces/IScholarshipFactory.sol";

contract ScholarshipFactory is IScholarshipFactory {
    function createNewScholarship(
        address _accessControll,
        address _rewardDistributor
    ) public override returns (address) {
        ScholarshipContract scholarshipContract = new ScholarshipContract(
            _accessControll,
            _rewardDistributor
        );
        return address(scholarshipContract);
    }
}
