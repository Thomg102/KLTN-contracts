//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../common/interfaces/ISharedStruct.sol";

interface IUITNFTToken is ISharedStruct {
    function uri(uint id) external returns (string memory);
    function setNFTInfo(uint _id, NFTInfo memory _nftInfo) external;
    function getNFTInfo(uint _id) external returns(NFTInfo memory);
    function getIdIndex() external returns (uint);

    function mint(address _account, uint _amount, NFTInfo memory _nftInfo) external;
    function mint(uint _id, address _account, uint _amount) external;
    function burn(uint _id, address _account, uint _amount) external;
    function burnBatch(uint[] memory _ids, address _account, uint[] memory _amounts) external;

    function createNFT(NFTInfo memory _nftInfo) external;

    event NFTMinted(uint indexed _id, address indexed _account, uint _amount, NFTInfo _nftInfo);
    event NFTInfoUpdated(uint indexed _id, NFTInfo _nftInfo);
    event NFTBurned(uint indexed _id, address indexed _account, uint _amount);
    event NFTBurnBatched(uint[] indexed _ids, address indexed _account, uint[] _amounts);
    event NFTCreated(uint indexed _id, NFTInfo _nftInfo);
}
