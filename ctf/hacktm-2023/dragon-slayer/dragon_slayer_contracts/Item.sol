// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./openzeppelin-contracts/access/Ownable.sol";
import "./openzeppelin-contracts/token/ERC1155/ERC1155.sol";

contract Item is ERC1155, Ownable {

    constructor() ERC1155("Item") { }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) public onlyOwner {
        _burn(from, id, amount);
    }
}
