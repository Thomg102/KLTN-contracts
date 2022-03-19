//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISharedStruct {
    struct NFTInfo {
        string metadataInHash;
        bool isCourseNFT;
    }
}


// check if the NFT is Course of Items:
// string memory empty = "";
// keccak256(bytes(_nftInfo.moreInfo)) != keccak256(bytes(empty));