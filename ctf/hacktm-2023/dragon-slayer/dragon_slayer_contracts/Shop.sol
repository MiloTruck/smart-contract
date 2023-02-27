// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Item.sol";
import "./GoldCoin.sol";

contract Shop {

    GoldCoin public goldCoin;
    Item public item;

    enum ItemType {
        NONE,
        SWORD,
        SHIELD
    }

    struct ItemProperties {
        string name;
        uint price;
        ItemType itemType;
        uint attack;
        uint defence;
        bool hasAntiFire;
    }

    mapping(uint => ItemProperties) public items;

    constructor(address goldCoin_) {
        goldCoin = GoldCoin(goldCoin_);
        item = new Item();

        item.mint(address(this), 1, 10, "");
        items[1] = ItemProperties(
            "Bronze Dagger",
            10 ether,
            ItemType.SWORD,
            1,
            0,
            false
        );

        item.mint(address(this), 2, 10, "");
        items[2] = ItemProperties(
            "Wooden Shield",
            10 ether,
            ItemType.SHIELD,
            0,
            1,
            false
        );

        item.mint(address(this), 3, 10, "");
        items[3] = ItemProperties(
            "Abyssal Whip",
            1_000_000 ether,
            ItemType.SWORD,
            1_000_000,
            0,
            false
        );

        item.mint(address(this), 4, 10, "");
        items[4] = ItemProperties(
            "Dragonfire Shield",
            1_000_000 ether,
            ItemType.SHIELD,
            0,
            1_000_000,
            true
        );

        item.mint(msg.sender, 1, 1, "");
        item.mint(msg.sender, 2, 1, "");
    }

    function buyItem(uint itemId) external {
        goldCoin.transferFrom(msg.sender, address(this), items[itemId].price);
        item.mint(msg.sender, itemId, 1, "");
    }

    function sellItem(uint itemId) external {
        item.burn(msg.sender, itemId, 1);
        goldCoin.transfer(msg.sender, items[itemId].price);
    }
}
