const { expect } = require("chai");
const { ethers } = require("hardhat");

CONTRACT_ADDRESS = '0x981D87E8ce55DE026eA8eE477c5ff789970048Fd';

describe("Call Me", function () {
  // Setup challenge
  before(async function() {
    const CallMeFactory = await ethers.getContractFactory("GuessTheNumberChallenge");
    // this.contract = await CallMeFactory.deploy({value: ethers.utils.parseEther('1')});
    this.contract = CallMeFactory.attach(CONTRACT_ADDRESS);
  });

  // Exploit code
  it('Exploit', async function() {
    await this.contract.guess(42, {value: ethers.utils.parseEther('1')});
  });

  // Success condition (only works locally)
  after(async function() {
    expect(
      await this.contract.isComplete()
    ).to.be.true;
  });

});