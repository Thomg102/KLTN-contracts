// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../SubjectContract.sol";
import "../interfaces/ISubjectFactory.sol";

contract SubjectFactory is ISubjectFactory {
    function createNewMission(address owner, address accessControll)
        public
        override
        returns (address)
    {
        SubjectContract subjectContract = new SubjectContract(
            owner,
            accessControll
        );
        return address(subjectContract);
    }
}
