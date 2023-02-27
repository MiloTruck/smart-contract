# Dragon Slayer

The contracts for this challenge can be found in [`dragon_slayer_contracts.zip`](dragon_slayer_contracts.zip).

## Challenge Overview

We are provided with the following basic contracts:
* `Setup.sol`: The contract used to setup the challenge and check if the challenge is solved.
* `Item.sol`: An ERC-1155 contract that implements items equippable by our knight.
* `GoldCoin.sol`: An ERC-20 contract that implements ERC-20 tokens, known as gold coins, which used as fungible currency.
* `BankNote.sol`: An ERC-721 contract that implements ERC-721 tokens, known as bank notes.

`Shop.sol` implements a contract to buy and sell items in exchange for gold coins. It sells the following items:

| `itemId` | `itemType`        | `attack`  | `defence` | `price`           |
| -------- | ----------------- | --------- | --------- | ----------------- |
| 1        | `ItemType.SWORD`  | 1         | 0         | `10 ether`        |
| 2        | `ItemType.SHIELD` | 0         | 1         | `10 ether`        |
| 3        | `ItemType.SWORD`  | 1,000,000 | 0         | `1_000_000 ether` |
| 4        | `ItemType.SHIELD` | 0         | 1,000,000 | `1_000_000 ether` |

`Dragon.sol` implements a contract that represents the enemy character, which has the following attributes:
* `health`: 1,000,000
* `clawAttack` and `fireAttack`: 1,000,000
* `defense`: 500,000 

`Knight.sol` implements a contract that represents our player, which also has its own `health`, `attack` and `defence` attributes. The relevant functions in the contract are:
* `fightDragon()`: Fights the dragon - receive an attack from the dragon and then attack it.
* `buyItem()`, `sellItem()`: Buy and sell items from the shop. Items that are bought are equipped, which changes the `attack` and `defence` attributes of the knight.
* `bankDeposit()`, `bankTransferPartial()`: Functions for the knight to interact with the `Bank` contract. Note that there are also other functions not listed here that interact with the `Bank` contract.

`Bank.sol` implements a `Bank` contract, which facillitates the exchange of gold coins for a non-fungible bank note. It has the following relevant functions:
  * `deposit()`: Deposit an amount of gold coins for a bank note.
  * `withdraw()`: Burn a bank note to withdraw its amount of gold coins.
  * `merge()`: Merge multiple bank notes into a new bank note.
  * `split()`: Split a single bank note into multiple new bank notes.
  * `transferPartial()`: Transfer an amount of gold coins from one bank note to another.

At the start of the challenge, the knight has only `10 ether` gold coins. The knight is also equipped with items `1` and `2`, thus he only has 1 `attack` and 1 `defense`.

Through the `Setup` contract, we are able to claim ownership of the knight:
```solidity
function claim() external {
    require(!claimed, "ALREADY_CLAIMED");
    claimed = true;
    knight.transferOwnership(msg.sender);
}
```

To solve the challenge, we have to reduce the dragon's health to 0 while our knight still has health:
```solidity
function isSolved() external view returns (bool) {
    return knight.health() > 0 && knight.dragon().health() == 0;
}
```

Essentially, we have to fight the dragon with our knight and defeat it. However, due to the dragon's high health, attack and defense attributes, the knight has to purchase and equip items `3` and `4` before fighting the dragon.

However, items `3` and `4` cost a total of `2_000_000 ether` gold coins, which is way more than what we have initially. Thus, we have to somehow create gold coins out of thin air...

## The vulnerability

In the `BankNote` contract, the `mint()` function uses `_safeMint()`:
```solidity
function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
}
```

`safeMint()` checks if the receiving address is capable of receiving ERC-721 tokens before minting the token. According to [OpenZeppelin's documentation](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721-_safeMint-address-uint256-):
> If `to` refers to a smart contract, it must implement `IERC721Receiver.onERC721Received`, which is called upon a safe transfer.

This means that if the receiving address is a smart contract, it has to implement an `onERC721Received()` function, which is expected to return `this.onERC721Received.selector`. 

In [OpenZeppelin's ERC-721 implementation](solve/src/dragon_slayer_contracts/openzeppelin-contracts/token/ERC721/ERC721.sol), whenever a token is minted to a contract, `_safeMint()` calls `_checkOnERC721Received()`, which invokes the `onERC721Received()` function of the receiving contract.

As such, when `mint()` is called in the `BankNote` contract, execution flow is passed to the receiving contract temporarily before the bank note is minted.

With this knowledge, we can spot a vulnerability in the `split()` function in `Bank.sol`:
```solidity
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
```

Notice the following: 
* If `msg.sender` is a contract, `bankNote.mint(msg.sender, bankNoteId)` allows `msg.sender` to hijack execution flow temporarily through `onERC721Received()` in the calling contract.
* The function first mints all resulting bank notes with their values from `amounts` before checking that the value of `bankNoteIdFrom` is equal to the sum of `amounts`, as seen in the `require` statement.

As the function performs minting, which interacts with `msg.sender` before the check, it violates the [Checks-Effects-Interactions pattern](https://docs.soliditylang.org/en/v0.8.19/security-considerations.html#re-entrancy), making it vulnerable to re-entrancy. This can be exploited to temporarily own any amount of gold coins:
1. An attacker contract calls `split()` with the following arguments:
   *  `bankNoteIdFrom` - a bank note with no value owned by the attacker. We'll call this *bankNoteA*.
   *  `amount` - `[x, 0]`, where `x` can be any arbitrary amount of gold coins the attacker needs.
2. In the first iteration of the for-loop in `split()`:
   * When `bankNote.mint()` is called, the attacker does nothing in the `onERC721Received()` callback.
   * A new bank note is minted to the attacker and assigned the value `x`. We'll call this *bankNoteB*
3. By the second iteration, the attacker owns *bankNoteB*, which has a value of `goldCoinAmount`. 
Thus, when `bankNote.mint()` is called again, the attacker does the following in the `onERC721Received()` callback:
   * Withdraws *bankNoteB* in exchange for `x` amount of gold coins and does whatever he wants with them.
   * Before `onERC721Received()` returns, the attacker has to deposit `x` amount of gold coins and transfer them to *bankNoteA*. 
4. When the for-loop terminates, the check at the end of `split()` passes as both `totalValue` and `bankNoteValues[bankNoteIDFrom]` equal to `x`.

For those who are familiar with smart contracts, this looks very similar to a [flash loan](https://docs.aave.com/faq/flash-loans). We can borrow any arbitrary amount of gold coins provided that we return them at the end of the function.

## Solving the challenge
With the vulnerability above, solving the challenge becomes trivial. We create an attacker contract which does the following:
1. **Obtain a bank note:** As our attacker contract has no gold coins, it cannot call `deposit()`. Instead, we call `merge()` with an empty array:
```solidity
// Get an empty banknote (id 1)
uint[] memory bankNoteIDsFrom = new uint[](0);
bank.merge(bankNoteIDsFrom);
```

2. **Exploit the vulnerability:** We then call `split()` with our empty bank note and `amount = [2_000_000 ether, 0]`, as we need `2_000_000 ether` worth of gold coins to buy items `3` and `4`.
3. **Fight the dragon:** In the second callback to `onERC721Received()`, we do the following:
   1. Withdraw our `2_000_000 ether` gold coins from the bank note.
   2. Transfer all gold coins to the knight.
   3. Knight buys items `3` and `4` with all the gold coins.
   4. Knight fights the dragon until its health is 0.
   5. Knight sells items `3` and `4` to gain back the `2_000_000 ether` gold coins. 
   6. Knight deposits the gold coins and transfers it to the attacker contract's bank note. 

The exploit contract, which implements the steps above, can be found in [`Exploit.sol`](solve/src/Exploit.sol).