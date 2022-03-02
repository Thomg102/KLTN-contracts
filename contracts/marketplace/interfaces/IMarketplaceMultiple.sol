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
    event MarketFeeUpdated(uint256 newMarketFee);
    event TokenValidUpdatedStatus(address token, bool status);

    struct SaleInfos {
        bool isSale;
        address item;
        address owner;
        uint256 itemId;
        uint256 amount;
        uint256 saleTime;
        uint256 price;
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
     * @notice Delist a item on sale.
     */
    function deList(uint256 _listedId) external;

    /**
     * @notice Instant buy a specific item on sale.
     */
    function buy(uint256 _listedId) external;
}
