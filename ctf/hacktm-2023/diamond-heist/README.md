# Diamond Heist

> Salty Pretzel Swap DAO has recently come out with their new flashloan vaults. They have deposited all of their 100 Diamonds in one of their vaults.
> 
> Your mission, should you choose to accept it, is to break the vault and steal all of the diamonds. This would be one of the greatest heists of all time.
> 
> This text will self-destruct in ten seconds.
> 
> Good luck.
>
> `nc 34.141.16.87 30200`

The contracts for this challenge can be found in [`diamond_heist_contracts.zip`](diamond_heist_contracts.zip).

## Overview

We are provided with the following contracts:
* `Setup.sol`: The contract used to setup the challenge and check if the challenge is solved.
* `Diamond.sol`: An ERC-20 contract that implements ERC-20 tokens known as diamonds.
* `Burner.sol`: A contract which contains a `selfdestruct` call to itself. (This contract is not important)

`SaltyPretzel.sol` is an ERC-20 contract that implements a governance token contract. Essentially, owning more SaltyPretzel tokens would give a user more votes, which is useful in a system that implements [governance](https://ethereum.org/en/governance/). This contract will be explained more in-depth later on.

`Vault.sol` implements a `Vault` contract that is used to store diamonds. It is meant to be an proxy implementation contract as it follows the [UUPSUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) pattern. It has the following interesting functions:
* `governanceCall()`: Allows the vault's owner or anyone with sufficient votes to execute any of this contract's functions.
* `flashloan()`: A function to take out a [flash loan](https://docs.aave.com/faq/flash-loans) of any token.

`VaultFactory.sol` contains a contract that deploys `Vault` as an [`ERC1967Proxy`](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy).

At the start of the challenge, 100 diamonds are transferred to the vault after it is initialized, as seen in `Setup.sol`:
```solidity
uint constant public DIAMONDS = 100;

// ...

constructor () {
    vaultFactory = new VaultFactory();
    vault = vaultFactory.createVault(keccak256("The tea in Nepal is very hot."));
    diamond = new Diamond(DIAMONDS);
    saltyPretzel = new SaltyPretzel();
    vault.initialize(address(diamond), address(saltyPretzel));
    diamond.transfer(address(vault), DIAMONDS);
}
```

Using the `claim()` function, we are able to mint `100 ether` worth of SaltyPretzel tokens for ourselves. This can only be done once:
```solidity
uint constant public SALTY_PRETZELS = 100 ether;

// ...

function claim() external {
    require(!claimed);
    claimed = true;
    saltyPretzel.mint(msg.sender, SALTY_PRETZELS);
}
```

To solve the challenge, the `Setup` contract must have a balance of 100 diamonds:
```solidity
function isSolved() external view returns (bool) {
    return diamond.balanceOf(address(this)) == DIAMONDS;
}
```

As all the diamonds were transferred to the vault at the start of the challenge, we have to  find a way to drain the vault of its 100 diamonds...

## The vulnerability

The `SaltyPretzel` contract implements its own accounting system to keep track of everyone's voting power. Users are also able to delegate their votes to another user, giving the delegatee more voting power. 

At the core of this vote accounting system are the `_delegate()` and `_moveDelegates()` functions:
```solidity
function _delegate(address delegator, address delegatee)
    internal
{
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
}

function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {
        if (srcRep != address(0)) {
            uint32 srcRepNum = numCheckpoints[srcRep];
            uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
            uint256 srcRepNew = srcRepOld - amount;
            _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
        }

        if (dstRep != address(0)) {
            uint32 dstRepNum = numCheckpoints[dstRep];
            uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
            uint256 dstRepNew = dstRepOld + amount;
            _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        }
    }
}
```

`_delegate()` first sets the `delegatee` of `delegator`, then calls `_moveDelegates()` to transfer the balance of `delegator` (ie. his votes) from the old delegatee to the new one.

`_moveDelegates()` then subtracts `amount` votes from `srcRep`, which in this case, would be the old delegatee, and adds them to `dstRep`, which would be the new delegatee. Notice the following checks:
* If `srcRep == dstRep` or `amount == 0`, the function does not do anything. 
* If `srcRep == address(0)`, the votes are not deducted from `srcRep`.
* If `dstRep == address(0)`, the votes are not added to `dstRep`.

Users can also change their `delegatee` through the `delegate()` function:
```solidity
function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
}
```

While looking at how `_moveDelegates()` is used, I noticed the following in `mint()`:
```solidity
function mint(address _to, uint256 _amount) public onlyOwner {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
}
```

When new tokens are minted, the contract has to "create" votes to increase the voting power of the recipient. To do so, `mint()` calls `_moveDelegates()` with `srcRep` as `address(0)`, which does not deduct votes from `srcRep` but simply adds them to `dstRep`.

This gave me an idea - if we could set our `delegatee` to `address(0)`, we would essentially be able to repeatedly create votes out of thin air, similar to `mint()`. Setting our `delegatee` to `address(0)` can be achieved by doing the following:
1. Transfer our SaltyPretzel tokens to another contract to make our balance 0.
2. Call `delegate()` with `address(0)` as our `delegatee`. This works as `_delegate()` would call `_moveDelegates()` with `amount = 0`, thus no transfer of votes occurs.

After setting `delegatee` to `address(0)`, we are able to increase the voting power of any other user through the following:
* Transfer our SaltyPretzel tokens back to our address.
* Call `delegate()`, with `delegatee` as the user we wish to add votes to. Note that `delegatee` cannot be our own address as `srcRep` cannot be equal to `dstRep` in `_moveDelegates()`, as mentioned above.

Thereforce, by repeatedly setting our `delegatee` to `address(0)`, then regaining our tokens and calling `delegate()`, we are able to increase anyone's voting power by any arbitrary amount.

## Solving the challenge

Now that we have the ability to gain infinite votes, how do we solve the challenge?

As `Vault` is a `UUPSUpgradeable` proxy contract, it inherits the an `upgradeTo()` function, which can be used to upgrade the implementation contract of `Vault`:
```solidity
function upgradeTo(address newImplementation) external virtual onlyProxy {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
}
````

The `_authorizeUpgrade()` function is overridden in the current implementation of `Vault`: 
```solidity
function _authorizeUpgrade(address) internal override view {
    require(msg.sender == owner() || msg.sender == address(this));
    require(IERC20(diamond).balanceOf(address(this)) == 0);
}
```

To change the implementation of `Vault` to our own contract, the following two requirements have to be met:
1. `msg.sender` has to be either owner or `Vault` itself.
2. `Vault` must have no diamonds.

Since the owner of `Vault` is the `Setup` contract, the first criteria can only be achieved by calling `upgradeTo()` through the `Vault` itself. Luckily for us, `Vault` contains a `governanceCall()` function:
```solidity
function governanceCall(bytes calldata data) external {
    require(msg.sender == owner() || saltyPretzel.getCurrentVotes(msg.sender) >= AUTHORITY_THRESHOLD);
    (bool success,) = address(this).call(data);
    require(success);
}
```

As we now have the ability to gain infinite votes, we can make `Vault` call any of its functions through `governanceCall()`. To meet the first requirement, we simply use `governanceCall()` to call `upgradeTo()`, which would make `msg.sender` the `Vault` itself.

To fulfil the second criteria, we utilize the `flashloan()` function:
```solidity
function flashloan(address token, uint amount, address receiver) external {
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(receiver, amount);
    IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, token, amount, 0, "");
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    require(balanceBefore == balanceAfter);
}
```
We take out a flashloan to borrow all of `Vault`'s diamonds, and then make the `governanceCall() -> upgradeTo()` call in the `onFlashLoan()` callback. This way, when `upgradeTo()` is called, `Vault` will temporarily have no diamonds.

## Exploit code
The exploit contract, which implements the steps above, can be found in [`Exploit.sol`](Exploit.sol). It contains three contracts:
* `Exploit` mainly handles abusing the vulnerability to gain sufficient votes.
* `VoteCollector` is used to solve the challenge after it has enough votes.
* `FakeVault` is the new vault implementation used to drain the vault.