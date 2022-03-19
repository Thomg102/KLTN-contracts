//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/interfaces/ISharedStruct.sol";

interface IMarketplace is ISharedStruct {
    struct SaleInfo {
        bool isActive;
        uint itemId;
        uint amount;
        uint saleTime;
        uint oneItemPrice;
    }

    event ItemListed(
        uint indexed itemId,
        uint amount,
        uint oneItemPrice,
        address ownerOfItem
    );
    event ItemDelisted(
        uint indexed itemId,
        uint amount,
        address ownerOfItem
    );
    event PriceUpdated(
        uint indexed itemId,
        uint _oneItemPrice,
        address ownerOfItem
    );
    event ItemBought(
        uint indexed itemId,
        address buyer,
        address seller,
        uint amount,
        uint price
    );
    event MarketFeeUpdated(uint newMarketFee);
    event TokenValidUpdatedStatus(address token, bool status);
    event AdminItemListed(
        uint indexed itemId,
        uint amount,
        uint oneItemPrice,
        address ownerOfItem
    );
    event AdminItemAmountUpdated(
        uint indexed itemId,
        uint amount,
        address ownerOfItem
    );

    /**
     * @notice List a item on sale.
     */
    function list(
        uint _id,
        uint _price,
        uint _amount
    ) external;

    /**
     * @notice Delist item on sale.
     */
    function deList(uint _itemId) external;

    /**
     * @notice Update price of one item on sale.
     */
    function updatePrice(uint _itemId, uint _oneItemPrice) external;

    /**
     * @notice Instant buy a specific item on sale.
     */
    function buy(uint _itemId, address _seller, uint _amount, uint _oneItemPrice) external;

    /**
     * @notice create and List NFT by Admin.
     */
    function createAndListNFT(NFTInfo memory _nftInfo, uint _oneItemPrice, uint _amount) external;

    /**
     * @notice Update amount to sell
     */
    function updateAmountNFT(uint _itemId, uint _amount) external;
}
