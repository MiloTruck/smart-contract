# Foundry

## Setup
To create a new project:
```sh
forge init <project_name>
```

## Adding Dependencies

To add a dependency, such as `@openzeppelin`:

1. `forge install openzeppelin/openzeppelin-contracts` (this will add the repo to lib/openzepplin-contracts)
2. Create a remappings file: `touch remappings.txt`
3. Add this line to `remappings.txt`
```
@openzeppelin/=lib/openzeppelin-contracts/
```

## Testing
Running tests with traces:
```sh
forge test -vvv
```

Mainnet Forking:
```sh
forge test --fork-url <ETH_RPC_URL>
```
