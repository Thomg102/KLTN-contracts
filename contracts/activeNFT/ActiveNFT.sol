//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IActiveNFT.sol";
import "../studentmanager/interfaces/IAccessControl.sol";
import "../token/interfaces/IUITNFTToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ActiveNFT is IActiveNFT, Pausable, Ownable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public accessControl;
    address public immutable UITNFT;

    bytes32 constant internal ADMIN_ROLE = keccak256("ADMIN");

    ActiveInfo[] public activeInfoList;

    constructor(
        address _accessControl,
        address _UITNFT
    ) {
        require(_accessControl != address(0), "ActiveNFT: Access control contract cannot be 0");
        require(_UITNFT != address(0), "ActiveNFT: UITNFToken must not be address 0");
        UITNFT = _UITNFT;
    }

    modifier onlyAdmin() {
        require(IAccessControl(accessControl).hasRole(ADMIN_ROLE, msg.sender), "Marketplace: Only admin can call this function");
        _;
    }

    /** USER
     * @dev Requset to activeNFT
     * @param _itemId itemId
     * @param _amount amount of item want to active
     */
    function requestActiveNFT(uint _itemId, uint _amount) external override whenNotPaused nonReentrant {
        require(_amount > 0, "ActiveNFT: amount is zero");
        require(IERC1155(UITNFT).balanceOf(msg.sender, _itemId) >= _amount, "ActiveNFT: Balance of items less than amount");
        uint activeId = activeInfoList.length;
        ActiveInfo memory activeInfo = ActiveInfo(
            activeId,
            msg.sender,
            _itemId,
            _amount,
            block.timestamp,
            0,
            true,
            false
        );
        NFTInfo memory nftInfo = IUITNFTToken(UITNFT).getNFTInfo(_itemId);

        if (nftInfo.isCourseNFT) {
            activeInfo.isRequested = true;

            emit NFTActived(activeId + 1, _itemId, _amount, block.timestamp, msg.sender, true);
        }
        else
            emit ActiveNFTRequested(_itemId, _amount, block.timestamp, msg.sender);

        activeInfoList.push(activeInfo);
        IERC1155(UITNFT).safeTransferFrom(msg.sender, address(this), _itemId, _amount, "");
    }

    /** USER
     * @dev cancel request active NFT
     * @param _activeId itemId
     */
    function cancelRequestActiveNFT(uint _activeId) external override whenNotPaused nonReentrant {
        ActiveInfo storage activeInfo = activeInfoList[_activeId];
        require(activeInfo.ownerOfRequest == msg.sender, "ActiveNFT: Not owner of request");
        require(activeInfo.isRequested, "ActiveNFT: activeInfo is not requested");
        require(!activeInfo.isActive, "ActiveNFT: activeInfo is already actived");
        uint itemId = activeInfo.itemId;

        activeInfo.isRequested = false;
        IERC1155(UITNFT).safeTransferFrom(address(this), msg.sender, itemId, activeInfo.amount, "");

        emit ActiveNFTRequestCanceled(_activeId, block.timestamp);
    }

    /** ADMIN
     * @dev active NFT
     * @param _activeId itemId
     */
    function activeNFT(uint _activeId) external override onlyAdmin whenNotPaused nonReentrant {
        ActiveInfo storage activeInfo = activeInfoList[_activeId];
        require(activeInfo.isRequested, "ActiveNFT: activeInfo is not requested");
        require(activeInfo.isActive, "ActiveNFT: activeInfo is already actived");
        uint itemId = activeInfo.itemId;

        activeInfo.isActive = true;
        activeInfo.activedTime = block.timestamp;

        NFTInfo memory nftInfo = IUITNFTToken(UITNFT).getNFTInfo(itemId);
        if (nftInfo.isCourseNFT)
            emit NFTActived(_activeId, itemId, activeInfo.amount, block.timestamp, msg.sender, true);
        else
            emit NFTActived(_activeId, itemId, activeInfo.amount, block.timestamp, msg.sender, false);
    }

    function setAccessControl(address _accessControl) external onlyOwner {
        accessControl = _accessControl;
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
