// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Knight.sol";

contract Setup {

    Knight public knight;

    bool public claimed;

    constructor() {
        knight = new Knight();

        knight.equipItem(1);
        knight.equipItem(2);
    }

    function claim() external {
        require(!claimed, "ALREADY_CLAIMED");
        claimed = true;
        knight.transferOwnership(msg.sender);
    }

    function isSolved() external view returns (bool) {
        return knight.health() > 0 && knight.dragon().health() == 0;
    }
}
