//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../common/OperatableUpgradeable.sol";
import "./interfaces/IUITNFTToken.sol";

contract UITNFTToken is ERC1155SupplyUpgradeable, OperatableUpgradeable, IUITNFTToken {

    using Strings for uint256;
    using Counters for Counters.Counter;

    string public name;
    string public symbol;

    uint public totalSupply;

    Counters.Counter private idIndex;

    mapping(uint => NFTInfo) nftInfo;
    mapping(uint => bool) public nonce;

    function initialize(string memory _name, string memory _symbol, string memory _uri) external initializer {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(_uri);
        __operatable_init();
    }

    function uri(uint id) public view override (ERC1155Upgradeable, IUITNFTToken) returns (string memory) {
        string memory _uri = super.uri(id);
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, id.toString())) : "";
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setNFTInfo(uint _id, NFTInfo memory _nftInfo)
        external
        override
        onlyOperator
    {
        nftInfo[_id] = _nftInfo;

        emit NFTInfoUpdated(_id, _nftInfo);
    }

    function getNFTInfo(uint _id) external view override onlyOperator returns(NFTInfo memory) {
        return nftInfo[_id];
    }

    function getIdIndex() external view override onlyOperator returns(uint) {
        return idIndex.current();
    }

    function mint(uint _id, address _account, uint _amount) public override onlyOperator virtual {
        require(_amount > 0, "UITNFTToken: Amount of items to mint must be more than 0");
        _mint(_account, _id, _amount, "");
        totalSupply += _amount;

        emit NFTMinted(_id, _account, _amount, nftInfo[_id]);
    }

    function mint(address _account, uint _amount, NFTInfo memory _nftInfo)
        external
        override
        onlyOperator
    {
        uint id = idIndex.current();
        require(!nonce[id], "UITNFTToken: itemId must be unique");
        nftInfo[id] = _nftInfo;
        mint(id, _account, _amount);
        nonce[id] = true;
        idIndex.increment();
    }

    function burn(uint _id, address _account, uint _amount) public override virtual {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "UITNFTToken: caller is not owner nor approved"
        );
        require(_amount > 0, "UITNFTToken: Amount of items to burn must be more than 0");
        require(balanceOf(_account, _id) >= _amount, "UITNFTToken: Not enough items to Burn");
        _burn(_account, _id, _amount);
        totalSupply -= _amount;

        emit NFTBurned(_id, _account, _amount);
    }

    function burnBatch(uint[] memory _ids, address _account, uint[] memory _amounts) public override {
        require(
            _account == _msgSender() || isApprovedForAll(_account, _msgSender()),
            "UITNFTToken: caller is not owner nor approved"
        );
        require(_ids.length == _amounts.length, "UITNFTToken: length of _ids, _amounts are not the same");
        uint totalBurnAmount;
        for (uint i; i < _ids.length; i++) {
            totalBurnAmount += _amounts[i];
        }
        _burnBatch(_account, _ids, _amounts);
        totalSupply -= totalBurnAmount;

        emit NFTBurnBatched(_ids, _account, _amounts);
    }
}
