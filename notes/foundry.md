# Foundry Cheatsheet

- [Foundry Cheatsheet](#foundry-cheatsheet)
  - [Setup](#setup)
  - [Dependencies](#dependencies)
    - [Adding dependencies](#adding-dependencies)
    - [Remappings](#remappings)
  - [Testing](#testing)
    - [Fork testing](#fork-testing)
    - [Useful Cheatcodes](#useful-cheatcodes)
      - [Global values](#global-values)
      - [Storage and memory](#storage-and-memory)
      - [Caller address](#caller-address)
      - [Balances](#balances)
      - [Testing reverts](#testing-reverts)
      - [Others](#others)
    - [Fuzzing](#fuzzing)

## Setup
Create a new project:
```sh
forge init <project_name>
```

Create a new project using a template:
```sh
forge init --template <template> <project_name>

# Example
forge init --template https://github.com/zobront/paradigm-ctf paradigm_ctf
```

## Dependencies

### Adding dependencies

Install dependencies in an existing project:
```sh
forge install
```

To add a new dependency:
```sh
forge install <dependency>

# Example
forge install openzeppelin/openzeppelin-contracts
```

### Remappings

Forge can automatically deduce remappings:
```sh
forge remappings
```

To customize a remapping, simply add it to `remappings.txt`:
```sh
echo "@openzeppelin/=lib/openzeppelin-contracts/" > remappings.txt
```

## Testing

To run tests:
```sh
forge test
```

Verbosity
- `-vv` shows `console.log` output.
- `-vvv` shows execution traces for failing tests. 
- `-vvvv` shows execution traces for all tests, and setup traces for failing tests.
- `-vvvvv` shows execution and setup traces for all tests.

To run specific tests:
- `--match-test` runs tests matching the specified regex.
- `--match-contract` runs tests in contracts matching the specified regex.
- `--match-path` runs tests in source files matching the specified path.

### Fork testing

To fork a network:
```sh
forge test --fork-url <rpc_url>
```

To identify contracts in a forked environment, pass your Etherscan API key using `--etherscan-api-key`:
```sh
forge test --fork-url <rpc_url> --etherscan-api-key <etherscan_api_key>
```

### Useful Cheatcodes

Refer to [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/) for all available cheatcodes.

#### Global values

```solidity
// Set block.timestamp
vm.warp(uint256 timestamp)

// Increase block.timestamp by specified seconds
skip(uint256 time)

// Decrease block.timestamp by specified seconds
rewind(uint256 time) 

// Set block.number
vm.roll(uint256 blockNumber)
```

#### Storage and memory

```solidity
// Load a storage slot from an address
vm.load(address account, bytes32 slot) 

// Store a value to an address' storage slot
vm.store(address account, bytes32 slot)

// Set code at address
vm.etch(address addr, bytes calldata code)
```

#### Caller address

```solidity
// Set msg.sender for the next call
vm.prank(address msgSender)` 

// Set msg.sender for subsequent calls
vm.startPrank(address msgSender)

// Reset msg.sender for subsequent calls
vm.stopPrank()

// Change msg.sender for subsequent calls
changePrank(address msgSender) 
```

#### Balances

```solidity
// Set ether balance for an address
deal(address to, uint256 balance)

// Set ERC20 token balance for an address
deal(address token, address to, uint256 balance)

// Set ERC20 token balance for an address and increase totalSupply if `adjust` is true
deal(address token, address to, uint256 balance, bool adjust)

// Give ERC721 token with `id` to an address
dealERC721(address token, address to, uint256 id)

// Set ERC1155 token balance for an address
dealERC1155(address token, address to, uint256 id, uint256 balance)

// Set ERC1155 token balance for an address and adjust totalSupply
dealERC1155(address token, address to, uint256 id, uint256 balance, bool adjust)
```

#### Testing reverts

```solidity
// Expect the next call to revert
vm.expectRevert()

// Expect the next call to revert with `message`
vm.expectRevert(bytes calldata message)

// Expect the next call to revert with `bytes4 data` (used for custom error selectors)
vm.expectRevert(bytes4 data)
```

#### Others

```solidity
// Create a labelled address
address addr = makeAddr(string memory name)

// Create a labelled address with private key
(address addr, uint256 privateKey) = makeAddrAndKey(string memory name)

// Sign data
(uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256 privateKey, bytes32 digest)
```

### Fuzzing

Use `vm.assume()` to specify conditions for inputs. It should only be used for narrow checks:
```solidity
function testSomething(uint256 v) public {
    vm.assume(v != 0);
    require(v != 0);
    ... 
}
```

Use `bound()` to restrict inputs to a certain range:
```solidity
function testSomething(uint256 v) public {
    v = bound(v, 100, 500);
    require(v >= 100 && v <= 500);
    ... 
}
```