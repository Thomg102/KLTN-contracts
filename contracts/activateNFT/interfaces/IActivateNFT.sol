//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/interfaces/ISharedStruct.sol";

interface IActivateNFT is ISharedStruct {
    struct ActivateInfo {
        uint activateId;
        address ownerOfRequest;
        uint itemId;
        uint amount;
        uint requestedTime;
        uint activatedTime;
        bool isRequested;
        bool isActivate;
    }

    event ActivateNFTRequested(uint _activateId, uint _itemId, uint _amount, uint _requestedTime, address _owner);
    event ActivateNFTRequestCanceled(uint[] _activateIds, uint _cancelRequestTime);
    event NFTActivated(uint _activateId, uint _itemId, uint _amount, uint _activatedTime, address _owner, bool _isCourseNFT);

    function requestActivateNFT(uint _itemId, uint _amount) external;
    function cancelRequestActivateNFT(uint[] memory _activateIds) external;
    function activateNFT(uint[] memory _activateIds) external;
}
