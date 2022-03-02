//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMarketplaceMultiple.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MarketplaceMultiple is IMarketplaceMultiple, Pausable, Ownable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;

    address public immutable UITToken;

    uint public marketFeeInBps = 500;
    uint constant BPS = 10000;
    uint constant ONE_DAY_DURATION = (1 days);
    uint public currentPriceStepDuration = (1 hours);
    uint public minOfferPercentInBPS = 2000;

    mapping(address => bool) public tokenValid;
    mapping(uint256 => SaleInfos) public itemsForSale;
    uint256 public numOffers;
    mapping(uint256 => mapping(address => uint)) public itemWithOffers;

    constructor(
        address _UITToken
    ) {
        require(_UITToken != address(0), "Marketplace: UITToken must not be address 0");
        UITToken = _UITToken;
    }

    /**
     * @dev Owner set new market fee
     * @param marketFee new market fee in Bps
     */
    function setMarketFeeInBps(uint marketFee) external onlyOwner {
        require(marketFee <= BPS * 30 / 100);
        marketFeeInBps = marketFee;
    }

    /**
     * @dev Seller lists a item on sale
     * @param _item item address
     * @param _itemId itemId
     * @param _price price of item want to sell
     * @param _amount amount of item want to sell
     */
    function list(address _item, uint _itemId, uint _price, uint _amount) external override whenNotPaused {
        require(tokenValid[_item], "Item invalid");
        require(_price > 0, "Marketplace: price is zero");
        require(_amount > 0, "Marketplace: amount is zero");
        require(IERC1155(_item).balanceOf(msg.sender, _itemId) >= _amount, "Marketplace: Balance of items less than amount");

        itemsForSale[numOffers] = SaleInfos(
            true,
            _item,
            msg.sender,
            _itemId,
            _amount,
            block.timestamp,
            _price
        );

        IERC1155(_item).safeTransferFrom(msg.sender, address(this), _itemId, _amount, "");

        emit ItemListed(numOffers++, _item, _itemId, _price, msg.sender);
    }

    /**
     * @dev Owner delists a item is being on sale.
     * @param _listedId id of offer
     */
    function deList(uint256 _listedId) external override {
        SaleInfos storage sale = itemsForSale[_listedId];
        require(_listedId < numOffers, "Item invalid");
        require(sale.owner == msg.sender, "Marketplace: You are not the seller");
        require(sale.isSale, "Marketplace: Sale inactive or already sold");

        IERC1155(sale.item).safeTransferFrom(address(this), msg.sender, sale.itemId, sale.amount, "");
        sale.isSale = false;

        emit ItemDelisted(_listedId, sale.item, sale.itemId, sale.owner);
    }

    /**
     * @dev Buyer buy a item is being on sale.
     * @param _listedId idItem of listed
     */
    function buy(uint256 _listedId) external override whenNotPaused nonReentrant {
        SaleInfos storage sale = itemsForSale[_listedId];
        address buyer = msg.sender;
        address seller = sale.owner;
        uint price = sale.price;

        require(_listedId < numOffers, "Item invalid");
        require(sale.isSale, "Marketplace: Sale inactive or already sold");
        require(buyer != seller, "Marketplace: owner cannot buy");

        IERC20(UITToken).safeTransferFrom(buyer, seller, price);
        IERC1155(sale.item).safeTransferFrom(address(this), buyer, sale.itemId, sale.amount, "");

        sale.isSale = false;

        emit ItemBought(_listedId, sale.item, sale.itemId, buyer, sale.owner, price);
    }

    /**
     * @dev set token valid status
     * @param _token token address
     */
    function setTokenValidStatus(address _token, bool _status) external onlyOwner {
        tokenValid[_token] = _status;

        emit TokenValidUpdatedStatus(_token, _status);
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
