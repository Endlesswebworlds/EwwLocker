import { ethers } from 'hardhat';
import { Contract, ContractFactory } from 'ethers';

async function main(): Promise<void> {
  const EwwLockerFactory: ContractFactory = await ethers.getContractFactory(
    'EwwLocker',
  );
  const EwwLocker: Contract = await EwwLockerFactory.deploy();
  await EwwLocker.deployed();
  console.log('EwwLocker deployed to: ', EwwLocker.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
