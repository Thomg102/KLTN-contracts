// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MyProxy is ERC1967Proxy{

    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data){
        _changeAdmin(msg.sender);
    }

    modifier onlyAdmin(){
        require(msg.sender == _getAdmin(), "CProxy: Only admin execute");
        _;
    }

    function getAdmin() external view returns(address){
        return _getAdmin();
    }

    function getImplementation() external view returns(address){
        return _getImplementation();
    }

    function upgradeTo(address newImplementation) external onlyAdmin{
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) external onlyAdmin{
        _upgradeToAndCall(newImplementation, data, forceCall);
    }
}