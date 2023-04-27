# Foundry

## Setup
To create a new project:
```sh
forge init <project_name>
```

## Adding Dependencies

To add a dependency, such as `@openzeppelin`:

1. Install Openzeppelin as a dependency:
```sh
forge install openzeppelin/openzeppelin-contracts
```
1. Add `@openzeppelin/=lib/openzeppelin-contracts/` to `remappings.txt`
```sh
echo "@openzeppelin/=lib/openzeppelin-contracts/" > remappings.txt
```

## Testing
Running tests with `console.log` output:
```sh
forge test -vvv
```

Running tests with traces:
```sh
forge test -vvv
```

Mainnet Forking:
```sh
forge test --fork-url <ETH_RPC_URL>
```
