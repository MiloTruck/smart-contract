# Foundry Cheatsheet

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
- `-vvv` shows traces. 

### Fork testing

To fork a network:
```sh
forge test --fork-url <rpc_url>
```

To identify contracts in a forked environment, pass your Etherscan API key using `--etherscan-api-key`:
```sh
forge test --fork-url <rpc_url> --etherscan-api-key <etherscan_api_key>
```

### Cheatcodes

### Fuzzing

### Invariant Testing
