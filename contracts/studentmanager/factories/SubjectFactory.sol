// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../SubjectContract.sol";
import "../interfaces/ISubjectFactory.sol";

contract SubjectFactory is ISubjectFactory {
    function createNewMission() public override returns (address) {
        SubjectContract subjectContract = new SubjectContract();
        return address(subjectContract);
    }
}
