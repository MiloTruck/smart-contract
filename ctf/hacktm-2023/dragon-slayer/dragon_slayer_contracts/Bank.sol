// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./openzeppelin-contracts/utils/Counters.sol";

import "./GoldCoin.sol";
import "./BankNote.sol";

contract Bank {
    using Counters for Counters.Counter;

    uint constant INITIAL_AMOUNT = 10 ether;
    
    Counters.Counter private _ids;

    GoldCoin public goldCoin;
    BankNote public bankNote;
    mapping(uint => uint) public bankNoteValues;

    constructor() {
        goldCoin = new GoldCoin();
        bankNote = new BankNote();

        goldCoin.mint(msg.sender, INITIAL_AMOUNT);
    }

    function deposit(uint amount) external {
        require(amount > 0, "ZERO");

        goldCoin.burn(msg.sender, amount);

        _ids.increment();
        uint bankNoteId = _ids.current();

        bankNote.mint(msg.sender, bankNoteId);
        bankNoteValues[bankNoteId] = amount;
    }

    function withdraw(uint bankNoteId) external {
        require(bankNote.ownerOf(bankNoteId) == msg.sender, "NOT_OWNER");

        bankNote.burn(bankNoteId);
        goldCoin.mint(msg.sender, bankNoteValues[bankNoteId]);
        bankNoteValues[bankNoteId] = 0;
    }

    function merge(uint[] memory bankNoteIdsFrom) external {
        uint totalValue;

        for (uint i = 0; i < bankNoteIdsFrom.length; i++) {
            uint bankNoteId = bankNoteIdsFrom[i];

            require(bankNote.ownerOf(bankNoteId) == msg.sender, "NOT_OWNER");
            bankNote.burn(bankNoteId);
            totalValue += bankNoteValues[bankNoteId];
            bankNoteValues[bankNoteId] = 0;
        }

        _ids.increment();
        uint bankNoteIdTo = _ids.current();
        bankNote.mint(msg.sender, bankNoteIdTo);
        bankNoteValues[bankNoteIdTo] += totalValue;
    }

    function split(uint bankNoteIdFrom, uint[] memory amounts) external {
        uint totalValue;
        require(bankNote.ownerOf(bankNoteIdFrom) == msg.sender, "NOT_OWNER");

        for (uint i = 0; i < amounts.length; i++) {
            uint value = amounts[i];

            _ids.increment();
            uint bankNoteId = _ids.current();

            bankNote.mint(msg.sender, bankNoteId);
            bankNoteValues[bankNoteId] = value;
            totalValue += value;
        }

        require(totalValue == bankNoteValues[bankNoteIdFrom], "NOT_ENOUGH");
        bankNote.burn(bankNoteIdFrom);
        bankNoteValues[bankNoteIdFrom] = 0;
    }

    function transferPartial(uint bankNoteIdFrom, uint amount, uint bankNoteIdTo) external {
        require(bankNote.ownerOf(bankNoteIdFrom) == msg.sender, "NOT_OWNER");
        require(bankNoteValues[bankNoteIdFrom] >= amount, "NOT_ENOUGH");

        bankNoteValues[bankNoteIdFrom] -= amount;
        bankNoteValues[bankNoteIdTo] += amount;
    }

    function transferPartialBatch(uint[] memory bankNoteIdsFrom, uint[] memory amounts, uint bankNoteIdTo) external {
        uint totalValue;

        for (uint i = 0; i < bankNoteIdsFrom.length; i++) {
            uint bankNoteId = bankNoteIdsFrom[i];
            uint value = amounts[i];

            require(bankNote.ownerOf(bankNoteId) == msg.sender, "NOT_OWNER");
            require(bankNoteValues[bankNoteId] >= value, "NOT_ENOUGH");

            bankNoteValues[bankNoteId] -= value;
        }

        bankNoteValues[bankNoteIdTo] += totalValue;
    }
}
