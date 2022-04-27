const { expect } = require("chai");
const { ethers } = require("hardhat");

CONTRACT_ADDRESS = '0x4E82133c1EDf3F86d05168EC69005a8907A4309e';

describe("Call Me", function () {
  // Setup challenge
  before(async function() {
    const CallMeFactory = await ethers.getContractFactory("CallMeChallenge");
    // this.contract = await CallMeFactory.deploy();
    this.contract = CallMeFactory.attach(CONTRACT_ADDRESS);
  });

  // Exploit code
  it('Exploit', async function() {
    await this.contract.callme();
  });

  // Success condition
  after(async function() {
    expect(
      await this.contract.isComplete()
    ).to.be.true;
  });

});