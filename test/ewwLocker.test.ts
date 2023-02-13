import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";

describe("Token", () => {
  async function deployContracts() {
    await mine(1000);
    const [deployer, sender, receiver] = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("EwwLocker");

    const tokenFactoryMock = await ethers.getContractFactory("MockToken");

    let contract = await tokenFactory.deploy();
    const mockTokenContract = await tokenFactoryMock.deploy(1000000);
    return { deployer, sender, receiver, contract, mockTokenContract };
  }

  async function addFunds() {
    let { contract, deployer, receiver, mockTokenContract } = await loadFixture(deployContracts);
    const worldId = 'worldId';
    const amount = 100;
    await mockTokenContract.functions.approve(contract.address, 1000000);
    await mockTokenContract.increaseAllowance(contract.address, 1000000)

    await (await contract.addFunds(mockTokenContract.address, worldId, amount)).wait();
    return { contract, deployer, receiver, worldId, tokenAdress: mockTokenContract.address, amount };
  }

  describe("addFunds", () => {
    it("should add funds to the contract", async () => {
      let { contract, tokenAdress, worldId, amount } = await loadFixture(addFunds);
      const funds = await contract.functions.funds(tokenAdress, worldId);
      expect(funds.toString()).to.equal(amount.toString());
    });
  });

  describe("retrieveFunds", () => {
    it("should retrieve funds from the contract", async () => {
      let { contract, tokenAdress, worldId, amount } = await loadFixture(addFunds);
      const newAllowedAddress = (await ethers.getSigners())[0];
      await contract.functions.allowAddress(tokenAdress, newAllowedAddress.address);
      await contract.functions.setDailyLimit(tokenAdress, worldId, 2);

      const currentLimit = await contract.functions.getCurrentLimit(tokenAdress, worldId);
      const currentLimitA = await contract.functions.getCurrentLimitA(tokenAdress, worldId);

      console.log(`currentLimit: ${currentLimit}`);
      console.log(`currentLimitA: ${currentLimitA}`);

      await contract.connect(newAllowedAddress).functions.retrieveFunds(tokenAdress, worldId, 1);
      const funds = await contract.functions.funds(tokenAdress, worldId);
      expect(funds.toString()).to.equal("99");
    });

    it("should not retrieve funds if the address is not authorized", async () => {
      let { contract, tokenAdress, worldId } = await loadFixture(addFunds);
      const newAllowedAddress = (await ethers.getSigners())[0];

      expect(contract.connect(newAllowedAddress).functions.retrieveFunds(tokenAdress, worldId, 1)).to.be.revertedWith("Address not authorized to retrieve funds");
    });

    it("should not retrieve funds if the daily limit is exceeded", async () => {
      let { contract, tokenAdress, worldId } = await loadFixture(addFunds);
      const newAllowedAddress = (await ethers.getSigners())[0];
      await contract.functions.allowAddress(tokenAdress, newAllowedAddress.address);
      await contract.functions.setDailyLimit(tokenAdress, worldId, 2);
  
      await contract.connect(newAllowedAddress).functions.retrieveFunds(tokenAdress, worldId, 2);
      expect(contract.connect(newAllowedAddress).functions.retrieveFunds(tokenAdress, worldId, 1)).to.be.revertedWith("You have already reached the daily limit.");
    });
  });

  describe("withdrawFunds", () => {
    it("should withdraw funds from the contract", async () => {
      let { contract, tokenAdress, worldId } = await loadFixture(addFunds);
      await contract.functions.withdrawFunds(tokenAdress, worldId);
      const funds = await contract.functions.funds(tokenAdress, worldId);
      expect(funds.toString()).to.equal("0");
    });

    it("should not withdraw funds if the address is not the owner", async () => {
      let { contract, tokenAdress, worldId } = await loadFixture(addFunds);
      const unauthorizedAddress = (await ethers.getSigners())[0];
  
      expect(contract.connect(unauthorizedAddress).functions.withdrawFunds(tokenAdress, worldId)).to.be.revertedWith("The msg.sender is not the owner of these funds");
    });
  });

  describe("allowAddress", () => {
    it("should allow an address to retrieve funds", async () => {
      let { contract, tokenAdress } = await loadFixture(addFunds);
      await contract.functions.allowAddress(tokenAdress, (await ethers.getSigners())[0].address);
      const allowed = await contract.functions.allowances(tokenAdress, (await ethers.getSigners())[0].address);
      expect(allowed[0]).to.be.true;
    });
  });

});
