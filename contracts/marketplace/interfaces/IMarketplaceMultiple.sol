//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceMultiple {
    event ItemListed(
        uint256 listedId,
        address item,
        uint256 indexed id,
        uint256 price,
        address ownerOfItem
    );
    event ItemListedByAuction(
        uint256 listedId,
        address item,
        uint256 itemId,
        uint256 listPrice,
        uint256 minPrice,
        uint256 startTime,
        uint256 duration,
        address seller
    );
    event ItemDelisted(
        uint256 listedId,
        address item,
        uint256 indexed itemId,
        address ownerOfItem
    );
    event ItemBought(
        uint256 listedId,
        address item,
        uint256 indexed itemId,
        address buyer,
        address seller,
        uint256 price
    );
    event ItemOffered(
        uint256 listedId,
        address item,
        uint256 indexed itemId,
        address buyer,
        uint256 price
    );
    event OfferTaken(
        uint256 listedId,
        address item,
        uint256 indexed itemId,
        address buyer,
        address seller,
        uint256 price
    );
    event OfferCanceled(
        uint256 listedId,
        address item,
        uint256 indexed itemId,
        address buyer
    );
    event MarketFeeUpdated(uint256 newMarketFee);
    event PriceStepDurationUpdated(uint256 priceStepDuration);
    event MinOfferPercentInBPSUpdated(uint256 minOfferPercentInBPS);
    event TokenValidUpdatedStatus(address token, bool status);

    struct SaleInfos {
        address item;
        uint256 itemId;
        uint256 amount;
        address owner;
        uint256 saleTime;
        uint256 listPrice;
        uint256 minPrice;
        uint256 auctionDuration;
        bool isSale;
    }

    /**
     * @notice List a item on sale.
     */
    function list(
        address _item,
        uint256 _id,
        uint256 _price,
        uint256 _amount
    ) external;

    /**
     * @notice List a item on sale by auction.
     */
    function listByAuction(
        address _item,
        uint256 _id,
        uint256 _listPrice,
        uint256 _minPrice,
        uint256 _duration,
        uint256 _amount
    ) external;

    /**
     * @notice Delist a item on sale.
     */
    function deList(uint256 _listedId) external;

    /**
     * @notice Instant buy a specific item on sale.
     */
    function buy(uint256 _listedId, uint256 _buyPrice) external;

    /**
     * @notice Gives offer for a item.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint256 _listedId, uint256 _offerValue) external;

    /**
     * @notice Owner take an offer to sell their item.
     *
     * Requirements:
     * - Cannot take offer under item's `floorPrice`.
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(
        uint256 _listedId,
        address _buyer,
        uint256 _offerValue
    ) external;

    /**
     * @notice Cancels an offer for a specific item.
     */
    function cancelOffer(uint256 _listedId) external;

    /**
     * @dev get current sale price
     */
    function getCurrentSalePrice(
        uint256 _listPrice,
        uint256 _minPrice,
        uint256 _duration,
        uint256 _startTime
    ) external view returns (uint256);
}
