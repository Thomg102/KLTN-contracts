//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/interfaces/ISharedStruct.sol";

interface IActiveNFT is ISharedStruct {
    struct ActiveInfo {
        uint activeId;
        address ownerOfRequest;
        uint itemId;
        uint amount;
        uint requestedTime;
        uint activedTime;
        bool isRequested;
        bool isActive;
    }

    event ActiveNFTRequested(uint _itemId, uint _amount, uint _requestedTime, address _owner);
    event ActiveNFTRequestCanceled(uint _activeId, uint _cancelRequestTime);
    event NFTActived(uint _activeId, uint _itemId, uint _amount, uint _activedTime, address _owner, bool _isCourseNFT);

    function requestActiveNFT(uint _itemId, uint _amount) external;
    function CancelRequestActiveNFT(uint _activeId) external;
    function activeNFT(uint _activeId) external;
}
