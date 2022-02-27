// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Art.sol";
import "./interfaces/IMarketPlace.sol";
import "./interfaces/ISignable.sol";

contract MarketPlaceV2 is Ownable, ISignable, IMarketPlace {
    using SafeERC20 for IERC20;

    Art art;

    address[] public sellers;
    mapping(uint256 => Product) public tokenIdToProduct;
    mapping(address => Product[]) public userToProduct; //creator anf their product
    mapping(uint256 => Offer[]) public tokenIdToOffer;
    mapping(string => bool) public checkTransactionId;
    mapping(string => bool) public imageExisted;

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(art.ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
     * @dev Sets the values for {art}.
     *
     * This value can be immutable: they can only be set once during
     * construction.
     */
    constructor(address _artAddr) {
        art = Art(_artAddr);
    }

    function selfDestruct(address to) public onlyOwner {
        address payable addr = payable(address(to));
        selfdestruct(addr);
        // TODO: get ERC20 tokens from other contracts.
    }

    function lazyTransactViaPrice(uint256 _tokenID, uint256 _timeout, bytes calldata _signature) public payable {
        Product storage _product = tokenIdToProduct[_tokenID];
        uint256 _sellPrice = msg.value;
        address _seller = art.ownerOf(_tokenID);

        require(_product.selling);
        require(art.getApproved(_tokenID) == address(this));
        require(msg.sender != _seller);

        bytes32 _message = keccak256(abi.encodePacked(_tokenID, _sellPrice, _timeout));
        require (recoverSigner(_message, _signature) == _seller);
        
        _product.selling = false;

        setOwnerRight(msg.sender, _tokenID);
        payment(_seller, msg.value);
    }

    function lazyTransactViaOffer(uint256 _tokenID, uint256 _amount, address _offerer, uint256 _timeout, address _token20, bytes calldata _signature) public {
        address _seller = art.ownerOf(_tokenID);
        Product storage _product = tokenIdToProduct[_tokenID];

        require(_product.selling);
        require (_seller != address(0));
        require(_token20 != address(0));
        require(_offerer != address(0));
        require(
            IERC20(_token20).allowance(_offerer, address(this)) >= _amount
        );
        require(_timeout >= block.timestamp);
        require(art.getApproved(_tokenID) == address(this));

        bytes32 _message = keccak256(abi.encodePacked(_tokenID, _amount, _token20, _timeout));
        require (recoverSigner(_message, _signature) == _offerer);

        tokenIdToOffer[_tokenID].push(Offer(
                _tokenID,
                _amount,
                _token20,
                _offerer,
                true,
                _timeout
            ));
        uint256 _index = tokenIdToOffer[_tokenID].length - 1;
        Offer storage _offer = tokenIdToOffer[_tokenID][_index];

        _product.selling = false;

        setOwnerRight(_offer.bargainer, _tokenID);

        payment(_offer.token20, _offer.bargainer, _seller, _offer.amount);

        emit NewOffer(
            _tokenID,
            _amount,
            _token20,
            _seller,
            block.timestamp + _timeout
        );
        emit ApproveOffer(_tokenID, _seller, msg.sender, _index);
    }
    /**
     * @dev See {IMarketplace-setArtAddr}.
     *
     * Requirements:
     *
     * - `_artAddr` cannot be the zero address.
     * - Only owner have right to call this function.
     */
    function setArtAddr(address _artAddr) public override onlyOwner {
        require(_artAddr != address(0));
        art = Art(_artAddr);
    }

    /**
     * @dev See {IMarketplace-createNewProduct}.
     *
     * Emits an {Transfer} event indicating the successful NFT generation
     *
     * Requirements:
     *
     * - `_hashImg` use only once.
     */
    function createNewProduct(
        string memory _hashInfo,
        string memory _hashImg,
        uint256 _price
    ) public override {
        require(!imageExisted[_hashImg], "");
        uint256 _tokenId = art.createNewNFT(msg.sender, _hashInfo);
        sellers.push(msg.sender);
        imageExisted[_hashImg] = true;
        Product memory product = Product(
            _tokenId,
            _price,
            true,
            true,
            msg.sender,
            0,
            block.timestamp
        );
        userToProduct[msg.sender].push(product);
        tokenIdToProduct[_tokenId] = product;
        // art.approve(address(this), _tokenId);
        emit Transfer(_tokenId, address(0), msg.sender);
    } //goi kem approve

    /**
     * @dev See {IMarketplace-setListOrNot}.
     */
    function setListOrNot(uint256 _tokenId)
        public
        override
        onlyOwnerOfToken(_tokenId)
    {
        Product storage product = tokenIdToProduct[_tokenId];
        product.listing = !product.listing;
    }

    /**
     * @dev See {IMarketplace-setSellOrNot}.
     */
    //neu tu false sang true thi phai goi kem approve
    function setSellOrNot(uint256 _tokenId)
        public
        override
        onlyOwnerOfToken(_tokenId)
    {
        Product storage product = tokenIdToProduct[_tokenId];
        product.selling = !product.selling;
    }

    /**
     * @dev See {IMarketplace-setPrice}.
     *
     * Requirements:
     *
     * - Only owner of `_tokenId` can call this function.
     */
    function setPrice(uint256 _tokenId, uint256 _price)
        public
        override
        onlyOwnerOfToken(_tokenId)
    {
        Product storage product = tokenIdToProduct[_tokenId];
        product.price = _price;
    }

    /**
     * @dev See {IMarketplace-getProductListCreated}.
     */
    function getProductListCreated(address _user)
        public
        view
        override
        returns (Product[] memory)
    {
        return userToProduct[_user];
    }

    /**
     * @dev See {IMarketplace-buyWithETH}.
     *
     * Requirements:
     *
     * - `_tokenId` product must be selling on market place
     * - must be approved first
     * - send value ETH equal price of product
     * - caller can not be owner of `_tokenId`
     */
    //Phai approve truoc
    function buyWithETH(uint256 _tokenId) public payable override {
        Product storage _product = tokenIdToProduct[_tokenId];
        require(_product.selling);
        require(art.getApproved(_tokenId) == address(this));
        require(msg.value == _product.price);
        require(msg.sender != art.ownerOf(_tokenId));

        _product.selling = false;
        address _owner = art.ownerOf(_tokenId);

        setOwnerRight(msg.sender, _tokenId);
        payment(_owner, msg.value);
    }

    /**
     * @dev See {IMarketplace-buyWithCurrency}.
     *
     * Requirements:
     *
     * - `_tokenId` product must be selling on market place
     * - must be approved first
     * - caller can not be owner of `_tokenId`
     * - `traransactionId` haven't used yet
     */
    function buyWithCurrency(uint256 _tokenId, string memory traransactionId)
        public
        override
    {
        Product storage _product = tokenIdToProduct[_tokenId];
        require(_product.selling);
        require(art.getApproved(_tokenId) == address(this));
        require(msg.sender != art.ownerOf(_tokenId));
        require(!checkTransactionId[traransactionId]);

        checkTransactionId[traransactionId] = true;
        _product.selling = false;

        setOwnerRight(msg.sender, _tokenId);
    }

    /**
     * @dev See {IMarketplace-getProducListOwnable}.
     */
    //lay ra danh sach cac san pham so huu
    function getProducListOwnable(address _owner)
        public
        view
        override
        returns (Product[] memory)
    {
        uint256[] memory arr = art.getTokenList(_owner);
        Product[] memory productList = new Product[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            productList[i] = tokenIdToProduct[arr[i]];
        }
        return productList;
    }

    /**
     * @dev See {IMarketplace-offer}.
     *
     * Emits an {NewOffer} event indicating the successful NewOffer generation
     *
     * Requirements:
     *
     * - `_tokenId`'s owner  must be selling on market place
     * - `_token20` address can not address zero
     * - caller must approve `_amount` token erc20 for this contract
     * - `_timeout` must be time in the future
     */
    //Phai goi kem approve token cho contractt nay
    function offer(
        uint256 _tokenId,
        uint256 _amount,
        address _token20,
        uint256 _timeout
    ) public override {
        Product storage _product = tokenIdToProduct[_tokenId];
        require(_product.selling);
        require(art.ownerOf(_tokenId) != address(0));
        require(_token20 != address(0));
        require(
            IERC20(_token20).allowance(msg.sender, address(this)) >= _amount
        );
        require(_timeout > block.timestamp);
        // IERC20(_token20).approve(address(this), _amount);

        tokenIdToOffer[_tokenId].push(
            Offer(_tokenId, _amount, _token20, msg.sender, false, _timeout)
        );
        emit NewOffer(
            _tokenId,
            _amount,
            _token20,
            msg.sender,
            _timeout
        );
    }

    /**
     * @dev See {IMarketplace-restartOffer}.
     *
     * Requirements:
     *
     * - `_tokenId`'s owner  must be selling on market place
     * - caller must be creator of offer
     * - `_timeout` must be time in the future
     */
    function restartOffer(
        uint256 _tokenId,
        uint256 _index,
        uint256 _timeout
    ) public override {
        require(tokenIdToOffer[_tokenId][_index].bargainer == msg.sender);
        require(tokenIdToOffer[_tokenId][_index].timeout < block.timestamp);
        require(_timeout > block.timestamp);
        tokenIdToOffer[_tokenId][_index].timeout = _timeout;
    }

    /**
     * @dev See {IMarketplace-getOffer}.
     */
    function getOffer(uint256 _tokenId, uint256 _index)
        public
        view
        override
        returns (Offer memory)
    {
        require(_index <= tokenIdToOffer[_tokenId].length);
        return tokenIdToOffer[_tokenId][_index];
    }

    function getOffer(uint256 _tokenId) public view returns (Offer[] memory) {
        return tokenIdToOffer[_tokenId];
    }

    /**
     * @dev See {IMarketplace-approveOffer}.
     *
     * Emits an {ApproveOffer} event indicating the successful approved offer
     *
     * Requirements:
     *
     * - `_tokenId`'s owner  must be selling on market place
     * and approved for this contract
     * - caller must be owner  of `_tokenId` product
     * - `_timeout` of offer must be greater than current timestamp
     */
    //chủ sở hữu da approve token721 hay chua
    function approveOffer(uint256 _tokenId, uint256 _index) public override {
        Product storage _product = tokenIdToProduct[_tokenId];
        Offer memory _offer = getOffer(_tokenId, _index);

        require(_product.selling);
        require(art.getApproved(_tokenId) == address(this));
        require(art.ownerOf(_tokenId) == msg.sender);
        require(_index <= tokenIdToOffer[_tokenId].length);
        require(block.timestamp <= _offer.timeout);

        tokenIdToOffer[_tokenId][_index].accepted = true;
        _product.selling = false;

        setOwnerRight(_offer.bargainer, _tokenId);

        address _owner = art.ownerOf(_tokenId);

        payment(_offer.token20, _offer.bargainer, _owner, _offer.amount);

        emit ApproveOffer(_tokenId, _owner, msg.sender, _index);
    }

    /**
     * @dev Update new owner for product.
     */
    function setOwnerRight(address buyer, uint256 _tokenId) internal {
        art.setOwnerToTokenId(buyer, _tokenId);
        address _owner = art.ownerOf(_tokenId);
        art.safeTransferFrom(_owner, buyer, _tokenId);
        emit Transfer(_tokenId, _owner, buyer);
    }

    /**
     * @dev Payment for ETH.
     */
    function payment(address _owner, uint256 _value) internal {
        Address.sendValue(payable(_owner), (_value * 98) / 100);
    }

    /**
     * @dev Payment for ERC20.
     */
    function payment(
        address _tokenEr20,
        address _sender,
        address _receipent,
        uint256 _amount
    ) internal {
        IERC20(_tokenEr20).safeTransferFrom(
            _sender,
            _receipent,
            (_amount * 95) / 100
        );
    }
}
