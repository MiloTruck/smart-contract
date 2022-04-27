const { expect } = require("chai");
const { ethers } = require("hardhat");

CONTRACT_ADDRESS = '0xce231D987c77DA58FA7d899D16FA612D6cB7700B';

describe("Call Me", function () {
  // Setup challenge
  before(async function() {
    const CallMeFactory = await ethers.getContractFactory("GuessTheSecretNumberChallenge");
    // this.contract = await CallMeFactory.deploy({value: ethers.utils.parseEther('1')});
    this.contract = CallMeFactory.attach(CONTRACT_ADDRESS);
  });

  // Exploit code
  it('Exploit', async function() {
    const answerHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;
    let ans;

    for (let i=0; i<256; i++) 
        if (ethers.utils.keccak256(i) == answerHash) {
            ans = i;
            break;
        }

    await this.contract.guess(ans, {value: ethers.utils.parseEther('1')});
  });

  // Success condition (only works locally)
  after(async function() {
    expect(
      await this.contract.isComplete()
    ).to.be.true;
  });

});