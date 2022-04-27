require("@nomiclabs/hardhat-waffle");

const { INFURA_API_KEY, PRIVATE_KEY } = process.env;

if (!INFURA_API_KEY)
  throw new Error(
    `INFURA_API_KEY env var not set. Copy .env.template to .env and set the env var`
  );
if (!PRIVATE_KEY)
  throw new Error(
    `PRIVATE_KEY env var not set. Copy .env.template to .env and set the env var`
  );


module.exports = {
  solidity: "0.4.21",
  networks: {
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
    }
  }
};