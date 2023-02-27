// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Dragon {
    
    address public knight;
    uint public health;
    uint public clawAttack;
    uint public fireAttack;
    uint public defence;
    uint public attackRound;

    constructor(address knight_) {
        knight = knight_;
        health = 1_000_000;
        clawAttack = 1_000_000;
        fireAttack = 10_000_000;
        defence = 500_000;
        attackRound = 0;
    }

    modifier onlyKnight() {
        require(msg.sender == knight, "ONLY_KNIGHT");
        _;
    }

    function doAttack() external onlyKnight returns (uint damage, bool isFire) {
        require(health > 0, "ALREADY_DEAD");

        if (attackRound % 5 == 0) {
            damage = fireAttack;
            isFire = true;
        } else {
            damage = clawAttack;
        }

        attackRound++;
    }

    function receiveAttack(uint damage) external onlyKnight {
        uint damageDone;
        if (damage > defence) {
            damageDone = damage - defence;
        }
        if (damageDone > health) {
            damageDone = health;
        }
        health -= damageDone;
    }
}
