// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./openzeppelin-contracts/access/Ownable.sol";

import "./Shop.sol";
import "./Bank.sol";
import "./Dragon.sol";

contract Knight is Ownable {
    
    Shop public shop;
    Item public item;
    Bank public bank;
    GoldCoin public goldCoin;
    Dragon public dragon;
    uint public health;
    uint public swordItemId;
    uint public shieldItemId;
    uint public attack;
    uint public defence;
    bool public hasAntiFire;

    constructor() {
        bank = new Bank();
        goldCoin = bank.goldCoin();
        shop = new Shop(address(goldCoin));
        item = shop.item();
        dragon = new Dragon(address(this));

        health = 10;
    }

    modifier onlyAlive() {
        require(health > 0, "GAME_OVER");
        _;
    }

    function equipItem(uint itemId) public onlyOwner onlyAlive {
        require(item.balanceOf(address(this), itemId) > 0, "NO_ITEM");
        (,,Shop.ItemType itemType,uint itemAttack,uint itemDefence,bool itemHasAntiFire) = shop.items(itemId);
        if (itemType == Shop.ItemType.SWORD) {
            _equipSword(itemId, itemAttack);
        } else if (itemType == Shop.ItemType.SHIELD) {
            _equipShield(itemId, itemDefence, itemHasAntiFire);
        } else {
            revert("NOT_EQUIPPABLE");
        }
    }

    function unequipItem(uint itemId) public onlyOwner onlyAlive {
        (,,Shop.ItemType itemType,,,) = shop.items(itemId);
        if (itemType == Shop.ItemType.SWORD) {
            require(swordItemId == itemId, "NOT_EQUIPPED");
            _unequipSword();
        } else if (itemType == Shop.ItemType.SHIELD) {
            require(shieldItemId == itemId, "NOT_EQUIPPED");
            _unequipShield();
        } else {
            revert("NOT_UNEQUIPPABLE");
        }
    }

    function _equipSword(uint itemId, uint itemAttack) private {
        swordItemId = itemId;
        attack = itemAttack;
    }

    function _unequipSword() private {
        swordItemId = 0;
        attack = 0;
    }

    function _equipShield(uint itemId, uint itemDefence, bool itemHasAntiFire) private {
        shieldItemId = itemId;
        defence = itemDefence;
        hasAntiFire = itemHasAntiFire;
    }

    function _unequipShield() private {
        shieldItemId = 0;
        defence = 0;
        hasAntiFire = false;
    }

    function buyItem(uint itemId) public onlyOwner onlyAlive {
        (,uint price,,,,) = shop.items(itemId);
        require(goldCoin.balanceOf(address(this)) >= price, "NOT_ENOUGH_GP");
        goldCoin.approve(address(shop), price);
        shop.buyItem(itemId);
        equipItem(itemId);
    }

    function sellItem(uint itemId) public onlyOwner onlyAlive {
        if (swordItemId == itemId || shieldItemId == itemId) {
            unequipItem(itemId);
        }
        shop.sellItem(itemId);
    }

    function bankDeposit(uint amount) external onlyOwner onlyAlive {
        goldCoin.approve(address(bank), amount);
        bank.deposit(amount);
    }

    function bankWithdraw(uint bankNoteId) external onlyOwner onlyAlive {
        bank.withdraw(bankNoteId);
    }
    
    function bankMerge(uint[] memory bankNoteIdsFrom) external onlyOwner onlyAlive {
        bank.merge(bankNoteIdsFrom);
    }
    
    function bankSplit(uint bankNoteIdFrom, uint[] memory amounts) external onlyOwner onlyAlive {
        bank.split(bankNoteIdFrom, amounts);
    }
    
    function bankTransferPartial(uint bankNoteIdFrom, uint amount, uint bankNoteIdTo) external onlyOwner onlyAlive {
        bank.transferPartial(bankNoteIdFrom, amount, bankNoteIdTo);
        
    }
    
    function bankTransferPartialBatch(uint[] memory bankNoteIdsFrom, uint[] memory amounts, uint bankNoteIdTo) external onlyOwner onlyAlive {
        bank.transferPartialBatch(bankNoteIdsFrom, amounts, bankNoteIdTo);
        
    }

    function fightDragon() public onlyOwner onlyAlive {
        (uint dragonDamage, bool isFire) = dragon.doAttack();
        _receiveAttack(dragonDamage, isFire);
        if (health > 0) {
            dragon.receiveAttack(attack);
        }
    }

    function _receiveAttack(uint damage, bool isFire) private {
        if (isFire && hasAntiFire) {
            return;
        }
        uint damageDone;
        if (damage > defence) {
            damageDone = damage - defence;
        }
        if (damageDone > health) {
            damageDone = health;
        }
        health -= damageDone;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
