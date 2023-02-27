// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./openzeppelin-contracts/access/Ownable.sol";
import "./openzeppelin-contracts/token/ERC20/ERC20.sol";

contract GoldCoin is ERC20, Ownable {

    constructor() ERC20("GoldCoin", "GC") { }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
