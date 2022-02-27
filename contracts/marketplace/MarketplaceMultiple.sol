//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMarketplaceMultiple.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MarketplaceMultiple is IMarketplaceMultiple, Pausable, Ownable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;

    address public immutable UITToken;
    address public immutable treasury;

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
        address _UITToken,
        address _treasury
    ) {
        require(_UITToken != address(0), "Marketplace: UITToken must not be address 0");
        require(_treasury != address(0), "Marketplace: Treasury must not be address 0");

        UITToken = _UITToken;
        treasury = _treasury;
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
     * @dev Seller lists a item on sale.
     * @param _item item address
     * @param _id itemId of sale
     * @param _price price of item want to sell
     * @param _amount amount of item want to sell
     */
    function list(address _item, uint _id, uint _price, uint _amount) external override whenNotPaused {
        require(tokenValid[_item], "Item invalid");
        require(_price > 0, "Marketplace: price is zero");
        require(_amount > 0, "Marketplace: amount is zero");
        require(IERC1155(_item).balanceOf(msg.sender, _id) >= _amount, "Marketplace: Balance of items less than amount");

        itemsForSale[numOffers] = SaleInfos(
            _item,
            _id,
            _amount,
            msg.sender,
            block.timestamp,
            _price,
            _price,
            0,
            true
        );

        IERC1155(_item).safeTransferFrom(msg.sender, address(this), _id, _amount, "");

        emit ItemListed(numOffers++, _item, _id, _price, msg.sender);
    }

    /**
     * @dev List a item on sale by auction.
     * @param _item item address
     * @param _id itemId of sale
     * @param _listPrice highest price of auction
     * @param _minPrice min price of auction
     * @param _duration duration of auction (day unit)
     * @param _amount amount of item want to sell
     */
    function listByAuction(address _item, uint _id, uint _listPrice, uint _minPrice, uint _duration, uint _amount) external override whenNotPaused {
        require(tokenValid[_item], "Item invalid");
        require(IERC1155(_item).balanceOf(msg.sender, _id) >= _amount, "Marketplace: Balance of items less than amount");
        require(_listPrice > 0, "Marketplace: listPrice need to be greater than zero");
        require(_minPrice > 0, "Marketplace: minPrice need to be greater than zero");
        require(_listPrice > _minPrice, "Marketplace: listPrice need to be greater than minPrice");
        require(_duration * ONE_DAY_DURATION > currentPriceStepDuration, "Marketplace: duration need to be greater than duration step");

        itemsForSale[numOffers] = SaleInfos(
            _item,
            _id,
            _amount,
            msg.sender,
            block.timestamp,
            _listPrice,
            _minPrice,
            _duration,
            true
        );

        IERC1155(_item).safeTransferFrom(msg.sender, address(this), _id, _amount, "");

        emit ItemListedByAuction(numOffers++, _item, _id, _listPrice, _minPrice, block.timestamp, _duration, msg.sender);
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
     * @param _listedId id of offer
     * @param _buyPrice price will be charged to buy that item
     */
    function buy(uint256 _listedId, uint _buyPrice) external override whenNotPaused nonReentrant {
        require(_listedId < numOffers, "Item invalid");
        SaleInfos storage sale = itemsForSale[_listedId];
        address buyer = msg.sender;

        require(sale.isSale, "Marketplace: Sale inactive or already sold");
        require(buyer != sale.owner, "Marketplace: owner cannot buy");

        uint price = getCurrentSalePrice(sale.listPrice, sale.minPrice, sale.auctionDuration, sale.saleTime);

        require(_buyPrice == price, "Marketplace: invalid trade price");

        IERC20(UITToken).safeTransferFrom(buyer, address(this), price);
        _makeTransaction(sale.item, sale.itemId, buyer, sale.owner, price, sale.amount);
        sale.isSale = false;

        emit ItemBought(_listedId, sale.item, sale.itemId, buyer, sale.owner, price);
    }

    /**
     * @dev Buyer gives offer for a item.
     * @param _listedId id of offer
     * @param _offerValue value of item which buyer want to offer
     */
    function offer(uint256 _listedId, uint _offerValue) external override whenNotPaused nonReentrant {
        require(_listedId < numOffers, "Item invalid");
        SaleInfos storage sale = itemsForSale[_listedId];
        address buyer = msg.sender;

        require(sale.isSale, "Marketplace: sale inactive or already sold");
        require(sale.listPrice == sale.minPrice, "Marketplace: Can't make an offer for a item that is listing by auction");
        require(buyer != sale.owner, "Marketplace: owner cannot offer");
        require(itemWithOffers[_listedId][buyer] == 0, "Marketplace: Please cancel current offer before you make new offer");
        require(_offerValue >= (sale.listPrice * minOfferPercentInBPS / BPS), "Marketplace: Offer at least 20% of the listing price.");

        uint listingPrice = getCurrentSalePrice(sale.listPrice, sale.minPrice, sale.auctionDuration, sale.saleTime);
        if (_offerValue >= listingPrice) {
            IERC20(UITToken).safeTransferFrom(buyer, address(this), _offerValue);
            _makeTransaction(sale.item, sale.itemId, buyer, sale.owner, _offerValue, sale.amount);
            sale.isSale = false;

            emit ItemBought(_listedId, sale.item, sale.itemId, buyer, sale.owner, _offerValue);
        }
        else {
            IERC20(UITToken).safeTransferFrom(buyer, address(this), _offerValue);

            itemWithOffers[_listedId][buyer] = _offerValue;

            emit ItemOffered(_listedId, sale.item, sale.itemId, buyer, _offerValue);
        }
    }

    /**
     * @dev Owner take an offer to sell their item.
     * @param _listedId id of offer
     * @param _buyer address of buyer who offerd for the item
     * @param _offerValue offer amount that seller accept from buyer
     */
    function takeOffer(uint256 _listedId, address _buyer, uint _offerValue) external override whenNotPaused nonReentrant {
        require(_listedId < numOffers, "Item invalid");
        SaleInfos storage sale = itemsForSale[_listedId];
        address seller = msg.sender;
        uint offeredValue = itemWithOffers[_listedId][_buyer];

        require(sale.isSale, "Marketplace: sale inactive or already sold");
        require(sale.listPrice == sale.minPrice, "Marketplace: Can't take an offer for a item that is listing by auction");
        require(_buyer != seller, "Marketplace: cannot buy your own item");
        require(offeredValue > 0, "Marketplace: no offer found");
        require(offeredValue >= _offerValue, "Marketplace: take offer amount have to be equal or higher than offered amount");
        require(sale.owner == msg.sender, "Marketplace: You are not the seller");

        _makeTransaction(sale.item, sale.itemId, _buyer, seller, offeredValue, sale.amount);
        itemWithOffers[_listedId][_buyer] = 0;
        sale.isSale = false;

        emit OfferTaken(_listedId, sale.item, sale.itemId, _buyer, seller, offeredValue);
    }

    /**
     * @dev Buyer cancel offer for a item which offered before.
     * @param _listedId id of offer
     */
    function cancelOffer(uint256 _listedId) external override nonReentrant {
        require(_listedId < numOffers, "Item invalid");

        address sender = msg.sender;
        uint offerValue = itemWithOffers[_listedId][sender];

        require(offerValue > 0, "Marketplace: no offer found");

        itemWithOffers[_listedId][sender] = 0;

        IERC20(UITToken).safeTransfer(sender, offerValue);

        emit OfferCanceled(_listedId, itemsForSale[_listedId].item, itemsForSale[_listedId].itemId, sender);
    }

    /**
     * @dev get current sale price
     * @param _listPrice highest price of auction
     * @param _minPrice min price of auction
     * @param _duration duration of auction (day unit)
     * @param _startTime time start auction (timestamp)
     */
    function getCurrentSalePrice(uint _listPrice, uint _minPrice, uint _duration, uint _startTime) public view override returns (uint){
        if (_listPrice == _minPrice) {
            return _listPrice;
        } else {
            uint gapTime = _duration * ONE_DAY_DURATION;
            if (block.timestamp > _startTime + gapTime) {
                return _minPrice;
            } else {
                uint timeSinceFeeStarted = block.timestamp - _startTime;
                uint stepsSinceAuctionStarted = timeSinceFeeStarted / currentPriceStepDuration;

                uint stepsNumber = gapTime / currentPriceStepDuration;
                uint gap = stepsNumber > 0
                ? (_listPrice - _minPrice) / stepsNumber
                : 0;

                return _listPrice - stepsSinceAuctionStarted * gap;
            }
        }
    }

    /**
     * @dev Owner set step duration
     * @param _priceStepDuration new price step duration
     */
    function setPriceStepDuration(uint _priceStepDuration) external onlyOwner {
        require(_priceStepDuration > 0, "Marketplace: New step duration has to be higher than 0");
        currentPriceStepDuration = _priceStepDuration;

        emit PriceStepDurationUpdated(_priceStepDuration);
    }

    /**
     * @dev Owner set Min Offer Percent In BPS
     * @param _minOfferPercentInBPS new min Offer Percent In BPS
     */
    function setMinOfferPercentInBPS(uint _minOfferPercentInBPS) external onlyOwner {
        require(_minOfferPercentInBPS > 0, "Marketplace: New Min Offer Percent In BPS has to be higher than 0");
        minOfferPercentInBPS = _minOfferPercentInBPS;

        emit MinOfferPercentInBPSUpdated(_minOfferPercentInBPS);
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

    /**
     * @dev Execute trade a item
     * @param _item item address
     * @param _id itemId of sale
     * @param _buyer address of buyer
     * @param _seller address of seller
     * @param _price price of the item
     */
    function _makeTransaction(address _item, uint _id, address _buyer, address _seller, uint _price, uint _amount) private {
        uint marketFee = _price * marketFeeInBps / BPS;

        bool transferToSeller = IERC20(UITToken).safeTransfer(_seller, _price - marketFee);
        require(transferToSeller);

        bool transferToTreasury = IERC20(UITToken).safeTransfer(treasury, marketFee);
        require(transferToTreasury);

        IERC1155(_item).safeTransferFrom(address(this), _buyer, _id, _amount, "");
    }
}
