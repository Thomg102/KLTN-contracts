// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Art is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    uint256 public totalSuply;
    Counters.Counter private _tokenIds;

    mapping(string => bool) public existed;
    mapping(address => uint256[]) public ownerToTokenId;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function createNewNFT(address _to, string memory _hash)
        public
        onlyOwner
        returns (uint256)
    {
        require(!existed[_hash], "Art: NFT is existed");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        existed[_hash] = true;
        ownerToTokenId[_to].push(newItemId);

        _mint(_to, newItemId);
        _setTokenURI(newItemId, _hash);

        totalSuply++;

        return newItemId;
    }

    function setOwnerToTokenId(address _to, uint256 _tokenId) public onlyOwner {
        ownerToTokenId[_to].push(_tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function getTokenList(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory arr = new uint256[](balanceOf(_owner));
        uint256 index = 0;
        for (uint256 i = 0; i < ownerToTokenId[_owner].length; i++) {
            if (ownerOf(ownerToTokenId[_owner][i]) == _owner) {
                arr[index] = ownerToTokenId[_owner][i];
                index++;
            }
        }
        return arr;
    }
}
