//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/interfaces/ISharedStruct.sol";

interface IMarketplace is ISharedStruct {
    struct SaleInfo {
        bool isActive;
        uint256 itemId;
        uint256 amount;
        uint256 saleTime;
        uint256 oneItemPrice;
    }

    event ItemListed(
        uint256 indexed itemId,
        uint256 amount,
        uint256 oneItemPrice,
        address ownerOfItem
    );
    event ItemDelisted(
        uint256 indexed itemId,
        uint256 amount,
        address ownerOfItem
    );
    event PriceUpdated(
        uint256 indexed itemId,
        uint256 _oneItemPrice,
        address ownerOfItem
    );
    event ItemBought(
        uint256 indexed itemId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 price
    );
    event MarketFeeUpdated(uint256 newMarketFee);
    event TokenValidUpdatedStatus(address token, bool status);
    event AdminItemListed(
        string hash,
        uint256 indexed itemId,
        uint256 amount,
        uint256 oneItemPrice,
        address ownerOfItem
    );
    event AdminItemAmountUpdated(
        uint256 indexed itemId,
        uint256 amount,
        address ownerOfItem
    );

    /**
     * @notice List a item on sale.
     */
    function list(
        uint256 _id,
        uint256 _price,
        uint256 _amount
    ) external;

    /**
     * @notice Delist item on sale.
     */
    function deList(uint256 _itemId) external;

    /**
     * @notice Update price of one item on sale.
     */
    function updatePrice(uint256 _itemId, uint256 _oneItemPrice) external;

    /**
     * @notice Instant buy a specific item on sale.
     */
    function buy(
        uint256 _itemId,
        address _seller,
        uint256 _amount
    ) external;

    /**
     * @notice create and List NFT by Admin.
     */
    function createAndListNFT(
        NFTInfo memory _nftInfo,
        uint256 _oneItemPrice,
        uint256 _amount
    ) external;

    /**
     * @notice Update amount to sell
     */
    function updateAmountNFT(uint256 _itemId, uint256 _amount) external;
}
