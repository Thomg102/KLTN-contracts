//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IActivateNFT.sol";
import "../studentmanager/interfaces/IAccessControl.sol";
import "../token/interfaces/IUITNFTToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ActivateNFT is
    IActivateNFT,
    Pausable,
    Ownable,
    ReentrancyGuard,
    ERC1155Holder
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public accessControl;
    address public marketplaceAddress;
    address public immutable UITNFT;

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN");

    ActivateInfo[] public activateInfoList;

    constructor(address _accessControl, address _UITNFT) {
        require(
            _accessControl != address(0),
            "ActivateNFT: Access control contract cannot be 0"
        );
        require(
            _UITNFT != address(0),
            "ActivateNFT: UITNFToken must not be address 0"
        );
        UITNFT = _UITNFT;
        accessControl = _accessControl;
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(accessControl).hasRole(ADMIN_ROLE, msg.sender),
            "Marketplace: Only admin can call this function"
        );
        _;
    }

    modifier onlyMarketplace() {
        require(msg.sender == marketplaceAddress);
        _;
    }

    function setMarketplaceAddress(address _marketplaceAddress)
        external
        onlyAdmin
    {
        marketplaceAddress = _marketplaceAddress;
    }

    /** USER
     * @dev Requset to activateNFT
     * @param _itemId itemId
     * @param _amount amount of item want to activate
     */
    function requestActivateNFT(uint _itemId, uint _amount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "ActivateNFT: amount is zero");
        require(
            IERC1155(UITNFT).balanceOf(msg.sender, _itemId) >= _amount,
            "ActivateNFT: Balance of items less than amount"
        );
        uint activateId = activateInfoList.length;
        ActivateInfo memory activateInfo = ActivateInfo(
            activateId,
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
            activateInfo.isRequested = true;

            emit NFTActivated(
                activateId + 1,
                _itemId,
                _amount,
                block.timestamp,
                msg.sender,
                true
            );
        } else
            emit ActivateNFTRequested(
                activateId + 1,
                _itemId,
                _amount,
                block.timestamp,
                msg.sender
            );

        activateInfoList.push(activateInfo);
        IERC1155(UITNFT).safeTransferFrom(
            msg.sender,
            address(this),
            _itemId,
            _amount,
            ""
        );
    }

    /** USER
     * @dev cancel request activate NFT
     * @param _activateIds itemId arrays
     */
    function cancelRequestActivateNFT(uint[] memory _activateIds)
        external
        override
        whenNotPaused
        nonReentrant
    {
        for (uint i = 0; i < _activateIds.length; i++){
            ActivateInfo storage activateInfo = activateInfoList[_activateIds[i]-1];
            require(
                activateInfo.ownerOfRequest == msg.sender,
                "ActivateNFT: Not owner of request"
            );
            require(
                activateInfo.isRequested,
                "ActivateNFT: activateInfo is not requested"
            );
            require(
                !activateInfo.isActivate,
                "ActivateNFT: activateInfo is already activated"
            );

            activateInfo.isRequested = false;
            IERC1155(UITNFT).safeTransferFrom(
                address(this),
                msg.sender,
                activateInfo.itemId,
                activateInfo.amount,
                ""
            );
        }

        emit ActivateNFTRequestCanceled(_activateIds, block.timestamp);
    }

    /** ADMIN
     * @dev activate NFT
     * @param _activateIds itemId arrays
     */
    function activateNFT(uint[] memory _activateIds)
        external
        override
        whenNotPaused
        nonReentrant
    {
        for (uint i = 0; i < _activateIds.length; i++){
            ActivateInfo storage activateInfo = activateInfoList[_activateIds[i] - 1];
            require(
                activateInfo.isRequested,
                "ActivateNFT: activateInfo is not requested"
            );
            require(
                !activateInfo.isActivate,
                "ActivateNFT: activateInfo is already activated"
            );
            uint itemId = activateInfo.itemId;

            activateInfo.isActivate = true;
            activateInfo.activatedTime = block.timestamp;

            NFTInfo memory nftInfo = IUITNFTToken(UITNFT).getNFTInfo(itemId);
            if (nftInfo.isCourseNFT)
                emit NFTActivated(
                    _activateIds[i],
                    itemId,
                    activateInfo.amount,
                    block.timestamp,
                    msg.sender,
                    true
                );
            else
                emit NFTActivated(
                    _activateIds[i],
                    itemId,
                    activateInfo.amount,
                    block.timestamp,
                    msg.sender,
                    false
                );
        }
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
