//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
import "../activateNFT/interfaces/IActivateNFT.sol";
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

contract Marketplace is
    IMarketplace,
    Pausable,
    Ownable,
    ReentrancyGuard,
    ERC1155Holder
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public accessControl;
    address public immutable UITToken;
    address public immutable UITNFT;
    address public immutable rewardDistributor;
    IActivateNFT public activateNFT;

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 internal constant STUDENT_ROLE = keccak256("STUDENT");

    mapping(uint256 => mapping(address => SaleInfo)) public itemsForSale;

    constructor(
        address _accessControl,
        address _UITToken,
        address _UITNFT,
        address _rewardDistributor,
        IActivateNFT _activateNFT
    ) {
        require(
            _accessControl != address(0),
            "Marketplace: Access control contract cannot be 0"
        );
        require(
            _UITToken != address(0),
            "Marketplace: UITToken must not be address 0"
        );
        require(
            _UITNFT != address(0),
            "Marketplace: UITNFToken must not be address 0"
        );
        require(
            _rewardDistributor != address(0),
            "Marketplace: RewardDistributor must not be address 0"
        );
        accessControl = _accessControl;
        UITToken = _UITToken;
        UITNFT = _UITNFT;
        rewardDistributor = _rewardDistributor;
        activateNFT = _activateNFT;
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(accessControl).hasRole(ADMIN_ROLE, msg.sender),
            "Marketplace: Only admin can call this function"
        );
        _;
    }

    modifier onlyStudent() {
        require(
            IAccessControl(accessControl).hasRole(STUDENT_ROLE, msg.sender),
            "Marketplace: Only student can call this function"
        );
        _;
    }

    /** USER
     * @dev Seller lists a item on sale
     * @param _itemId itemId
     * @param _oneItemPrice price of one item want to sell
     * @param _amount amount of item want to sell
     */
    function list(
        uint256 _itemId,
        uint256 _oneItemPrice,
        uint256 _amount
    ) external override whenNotPaused nonReentrant onlyStudent {
        require(_oneItemPrice > 0, "Marketplace: price is zero");
        require(_amount > 0, "Marketplace: amount is zero");
        require(
            IERC1155(UITNFT).balanceOf(msg.sender, _itemId) >= _amount,
            "Marketplace: Balance of items less than amount"
        );
        SaleInfo memory saleInfo = itemsForSale[_itemId][msg.sender];
        require(!saleInfo.isActive, "Marketplace: Item is already listed");
        require(saleInfo.amount == 0, "Marketplace: Item is already listed");

        itemsForSale[_itemId][msg.sender] = SaleInfo(
            true,
            _itemId,
            _amount,
            block.timestamp,
            _oneItemPrice
        );

        IERC1155(UITNFT).safeTransferFrom(
            msg.sender,
            address(this),
            _itemId,
            _amount,
            ""
        );

        emit ItemListed(_itemId, _amount, _oneItemPrice, msg.sender);
    }

    /** USER
     * @dev Owner delists item is being on sale.
     * @param _itemId id of item want to delist
     */
    function deList(uint256 _itemId)
        external
        override
        whenNotPaused
        nonReentrant
        onlyStudent
    {
        address seller = msg.sender;
        SaleInfo storage sale = itemsForSale[_itemId][seller];
        require(sale.isActive, "Marketplace: Sale inactivate or already sold");

        uint256 amount = sale.amount;
        sale.isActive = false;

        IERC1155(UITNFT).safeTransferFrom(
            address(this),
            seller,
            _itemId,
            amount,
            ""
        );

        emit ItemDelisted(_itemId, amount, seller);
    }

    /** USER, ADMIN
     * @dev Seller update price of one item
     * @param _itemId id of item want to update price
     * @param _oneItemPrice new price of one item
     */
    function updatePrice(uint256 _itemId, uint256 _oneItemPrice)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address seller = msg.sender;
        SaleInfo storage sale = itemsForSale[_itemId][seller];
        require(_oneItemPrice > 0, "Marketplace: price is zero");

        sale.oneItemPrice = _oneItemPrice;

        emit PriceUpdated(_itemId, _oneItemPrice, seller);
    }

    /** USER
     * @dev Buyer buy amount of items is being on sale.
     * @param _itemId id of item want to buy
     * @param _seller seller address
     * @param _amount amount of item want to buy
     */
    function buy(
        uint256 _itemId,
        address _seller,
        uint256 _amount
    ) external override whenNotPaused nonReentrant onlyStudent {
        SaleInfo storage sale = itemsForSale[_itemId][_seller];
        address buyer = msg.sender;
        uint256 oneItemPrice = sale.oneItemPrice;
        uint256 price = _amount * oneItemPrice;

        require(sale.isActive, "Marketplace: Sale inactivate or already sold");
        require(
            _amount <= sale.amount,
            "Marketplace: Not enough amount to sell"
        );
        require(buyer != _seller, "Marketplace: owner cannot buy");

        sale.amount -= _amount;
        if (sale.amount == 0) sale.isActive = false;

        IERC20(UITToken).safeTransferFrom(buyer, _seller, price);

        // If seller is Admin, mint NFT to buyer
        if (IAccessControl(accessControl).hasRole(ADMIN_ROLE, _seller)) {
            IERC20(UITToken).safeTransferFrom(buyer, rewardDistributor, price);
            IUITNFTToken(UITNFT).mint(_itemId, buyer, _amount);
        } else {
            IERC20(UITToken).safeTransferFrom(buyer, _seller, price);
            IERC1155(UITNFT).safeTransferFrom(
                address(this),
                buyer,
                sale.itemId,
                _amount,
                ""
            );
        }

        emit ItemBought(_itemId, buyer, _seller, _amount, price);
    }

    /** ADMIN
     * @dev create and list items on sale.
     * @param _nftInfo info of NFT want to create
     * @param _oneItemPrice price of one item want to sell
     * @param _amount amount of item want to sell
     */
    function createAndListNFT(
        NFTInfo memory _nftInfo,
        uint256 _oneItemPrice,
        uint256 _amount
    ) external override whenNotPaused nonReentrant onlyAdmin {
        require(_oneItemPrice > 0, "Marketplace: price must not be zero");
        require(_amount > 0, "Marketplace: amount must not be zero");
        IUITNFTToken(UITNFT).createNFT(_nftInfo);
        uint256 itemId = IUITNFTToken(UITNFT).getIdIndex();

        SaleInfo memory saleInfo = itemsForSale[itemId][msg.sender];
        require(!saleInfo.isActive, "Marketplace: Item is already listed");

        itemsForSale[itemId][msg.sender] = SaleInfo(
            true,
            itemId,
            _amount,
            block.timestamp,
            _oneItemPrice
        );

        emit AdminItemListed(
            _nftInfo.metadataInHash,
            itemId,
            _amount,
            _oneItemPrice,
            msg.sender
        );
    }

    /** ADMIN
     * @dev update amount NFT to sell
     * @param _itemId id of item want to buy
     * @param _amount amount of item want to sell
     */
    function updateAmountNFT(uint256 _itemId, uint256 _amount)
        external
        override
        whenNotPaused
        nonReentrant
        onlyAdmin
    {
        SaleInfo storage sale = itemsForSale[_itemId][msg.sender];
        bool isSale = sale.isActive;

        if (_amount == 0 && isSale) sale.isActive = false;
        else if (sale.amount == 0 && !isSale) sale.isActive = true;

        sale.amount = _amount;

        emit AdminItemAmountUpdated(_itemId, _amount, msg.sender);
    }

    function requestActivateNFT(uint256 _itemId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        onlyStudent
    {
        activateNFT.requestActivateNFT(_itemId, _amount);
    }

    function cancelRequestActivateNFT(uint256[] memory _activateIds)
        external
        whenNotPaused
        nonReentrant
        onlyStudent
    {
        activateNFT.cancelRequestActivateNFT(_activateIds);
    }

    function activateNFTByAdmin(uint256[] memory _activateIds)
        external
        whenNotPaused
        nonReentrant
        onlyAdmin
    {
        activateNFT.activateNFT(_activateIds);
    }

    function setAccessControl(address _accessControl) external onlyOwner {
        accessControl = _accessControl;
    }

    function setActivateNFT(IActivateNFT _activateNFT) external onlyOwner {
        activateNFT = _activateNFT;
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
