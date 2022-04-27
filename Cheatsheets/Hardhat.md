# Hardhat

## Creating a new Hardhat project

In the project directory, run:
```shell
npm init --yes
npm install --save-dev hardhat
npx hardhat
```

## Running tests
```shell
# Run test locally
npx hardhat test path/to/test.js

# Run test on testnet
npx hardhat test path/to/test.js --network ropsten
```