// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./openzeppelin-contracts/access/Ownable.sol";
import "./openzeppelin-contracts/token/ERC721/ERC721.sol";

contract BankNote is ERC721, Ownable {

    constructor() ERC721("BankNote", "BN") { }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
}
