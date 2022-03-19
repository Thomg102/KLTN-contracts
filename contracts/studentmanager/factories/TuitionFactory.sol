// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../TuitionContract.sol";
import "../interfaces/ITuitionFactory.sol";

contract TuitionFactory is ITuitionFactory {
    function createNewTuition(
        address _accessControll,
        address _rewardDistributor
    ) public override returns (address) {
        TuitionContract tuitionContract = new TuitionContract(
            _accessControll,
            _rewardDistributor
        );
        return address(tuitionContract);
    }
}
