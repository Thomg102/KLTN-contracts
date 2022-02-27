//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarketPlace {
    struct Product {
        uint256 tokenId;
        uint256 price;
        bool listing;
        bool selling;
        address creator;
        uint256 rate;
        uint256 timestamp;
    }

    struct Offer {
        uint256 tokenId;
        uint256 amount;
        address token20;
        address bargainer;
        bool accepted;
        uint256 timeout;
    }

    event Transfer(
        uint256 indexed _tokenId,
        address indexed _oldOwner,
        address indexed _newOwner
    );
    event NewOffer(
        uint256 indexed _tokenId,
        uint256 _amount,
        address _token20,
        address indexed _bargainer,
        uint256 _timeout
    );
    event ApproveOffer(
        uint256 indexed _tokenId,
        address indexed _oldOwner,
        address indexed _newOwner,
        uint256 _index
    );

    /**
     * @dev Sets the contract address for creating NFT
     */
    function setArtAddr(address _artAddr) external;

    /**
     * @dev Create product that will list on market place.
     */
    function createNewProduct(
        string memory _hashInfo,
        string memory _hashImg,
        uint256 _price
    ) external;

    /**
     * @dev Set a product if it listed on market place or not.
     */
    function setListOrNot(uint256 _tokenId) external;

    /**
     * @dev Set a product if it sold or not.
     */
    function setSellOrNot(uint256 _tokenId) external;

    /**
     * @dev Set price to product with its tokenId.
     */
    function setPrice(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Return the product list listing on market place
     */
    function getProductListCreated(address _user)
        external
        view
        returns (Product[] memory);

    /**
     * @dev Moves `_tokenId` product from its owner to `sender` using the.
     * `sender` pass a mount ETH, this will transfer to owner of `_tokenId`
     */
    function buyWithETH(uint256 _tokenId) external payable;

    function buyWithCurrency(uint256 _tokenId, string memory traransactionId)
        external;

    /**
     * @dev Return the product list of `owner`
     */
    function getProducListOwnable(address _owner)
        external
        view
        returns (Product[] memory);

    /**
     * @dev Create a offer to negotiate the product `_tokenId`
     */
    function offer(
        uint256 _tokenId,
        uint256 _amount,
        address _token20,
        uint256 _timeout
    ) external;

    /**
     * @dev Restart time for offer timeout with `_tokenId`
     */
    function restartOffer(
        uint256 _tokenId,
        uint256 _index,
        uint256 _timeout
    ) external;

    
    function getOffer(uint256 _tokenId, uint256 _index)
        external
        view
        returns (Offer memory);

    function approveOffer(uint256 _tokenId, uint256 _index) external;
}
