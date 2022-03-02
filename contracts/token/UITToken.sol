// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UITToken is ERC20, Ownable {

    constructor () ERC20("University of Infomation Technology", "UIT") {
        _mint(msg.sender, 1e9 ether);
    }

    function burn(uint amount) external onlyOwner{
        _burn(msg.sender, amount);
    }
}
