//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMarketplace.sol";
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

contract Marketplace is IMarketplace, Pausable, Ownable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public immutable UITToken;
    address public immutable UITNFT;

    mapping(uint => mapping(address => SaleInfo)) public itemsForSale;

    constructor(
        address _UITToken,
        address _UITNFT
    ) {
        require(_UITToken != address(0), "Marketplace: UITToken must not be address 0");
        require(_UITNFT != address(0), "Marketplace: UITNFToken must not be address 0");
        UITToken = _UITToken;
        UITNFT = _UITNFT;
    }

    /** USER
     * @dev Seller lists a item on sale
     * @param _itemId itemId
     * @param _oneItemPrice price of one item want to sell
     * @param _amount amount of item want to sell
     */
    function list(uint _itemId, uint _oneItemPrice, uint _amount) external override whenNotPaused nonReentrant {
        require(_oneItemPrice > 0, "Marketplace: price is zero");
        require(_amount > 0, "Marketplace: amount is zero");
        require(IERC1155(UITNFT).balanceOf(msg.sender, _itemId) >= _amount, "Marketplace: Balance of items less than amount");
        SaleInfo memory saleInfo = itemsForSale[_itemId][msg.sender];
        require(!saleInfo.isActive, "Marketplace: Item is already listed");

        itemsForSale[_itemId][msg.sender] = SaleInfo(
            true,
            _itemId,
            _amount,
            block.timestamp,
            _oneItemPrice
        );

        IERC1155(UITNFT).safeTransferFrom(msg.sender, address(this), _itemId, _amount, "");

        emit ItemListed(_itemId, _amount, _oneItemPrice, msg.sender);
    }

    /** USER
     * @dev Owner delists item is being on sale.
     * @param _itemId id of item want to delist
     */
    function deList(uint _itemId) external override whenNotPaused nonReentrant {
        address seller = msg.sender;
        SaleInfo storage sale = itemsForSale[_itemId][seller];
        require(sale.isActive, "Marketplace: Sale inactive or already sold");

        uint amount = sale.amount;
        sale.isActive = false;

        IERC1155(UITNFT).safeTransferFrom(address(this), seller, _itemId, amount, "");

        emit ItemDelisted(_itemId, amount, seller);
    }

    /** USER, ADMIN
     * @dev Seller update price of one item
     * @param _itemId id of item want to update price
     * @param _oneItemPrice new price of one item
     */
    function updatePrice(uint _itemId, uint _oneItemPrice) external override whenNotPaused nonReentrant {
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
     * @param _oneItemBuyPrice price of one item want to buy
     */
    function buy(uint _itemId, address _seller, uint _amount, uint _oneItemBuyPrice) external override whenNotPaused nonReentrant {
        SaleInfo storage sale = itemsForSale[_itemId][_seller];
        address buyer = msg.sender;
        uint oneItemPrice = sale.oneItemPrice;
        uint price = _amount * oneItemPrice;

        require(sale.isActive, "Marketplace: Sale inactive or already sold");
        require(_amount <= sale.amount, "Marketplace: Not enough amount to sell");
        require(_oneItemBuyPrice == oneItemPrice, "Marketplace: invalid trade price");
        require(buyer != _seller, "Marketplace: owner cannot buy");

        sale.amount -= _amount;
        if (sale.amount == 0)
            sale.isActive = false;

        IERC20(UITToken).safeTransferFrom(buyer, _seller, price);

        // If seller is Admin, mint NFT to buyer
        if (_seller == owner())
            IUITNFTToken(UITNFT).mint(_itemId, buyer, _amount);
        else 
            IERC1155(UITNFT).safeTransferFrom(address(this), buyer, sale.itemId, sale.amount, "");
        
        emit ItemBought(_itemId, buyer, _seller, _amount, price);
    }

    /** ADMIN
     * @dev create and list items on sale.
     * @param _nftInfo info of NFT want to create
     * @param _oneItemPrice price of one item want to sell
     * @param _amount amount of item want to sell
     */
    function createAndListNFT(NFTInfo memory _nftInfo, uint _oneItemPrice, uint _amount) external override whenNotPaused nonReentrant {
        require(_oneItemPrice > 0, "Marketplace: price must not be zero");
        require(_amount > 0, "Marketplace: amount must not be zero");
        IUITNFTToken(UITNFT).createNFT(_nftInfo);
        uint itemId = IUITNFTToken(UITNFT).getIdIndex();

        SaleInfo memory saleInfo = itemsForSale[itemId][msg.sender];
        require(!saleInfo.isActive, "Marketplace: Item is already listed");

        itemsForSale[itemId][msg.sender] = SaleInfo(
            true,
            itemId,
            _amount,
            block.timestamp,
            _oneItemPrice
        );

        emit AdminItemListed(itemId, _amount, _oneItemPrice, msg.sender);
    }

    /** ADMIN
     * @dev update amount NFT to sell
     * @param _itemId id of item want to buy
     * @param _amount amount of item want to sell
     */
    function updateAmountNFT(uint _itemId, uint _amount) external override whenNotPaused nonReentrant {
        SaleInfo storage sale = itemsForSale[_itemId][msg.sender];
        bool isSale = sale.isActive;

        if (_amount == 0 && isSale)
            sale.isActive = false;
        else if (sale.amount == 0 && !isSale)
            sale.isActive = true;

        sale.amount = _amount;

        emit AdminItemAmountUpdated(_itemId, _amount, msg.sender);
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
