# EwwLocker

Funds can be send to the locker to fund a world, to achive relative secure transfer operations or 
a automated airdrop mechanism

## Steps to do

1. Call Approve on the token contract (e.g USDC) and as sender use the EwwLocker contract address 
2. Call AddFunds 
3. Call SetDailyLimit
4. Call AllowAddress to Node Address that can operate 


## Current EwwLocker addresses

1. Matic = 0x3Ea5432C0435Da5db06edBb83917f68B66F06bA3


## Usage

### Pre Requisites

Before running any command, make sure to install dependencies:

```sh
yarn install
```

### Compile

Compile the smart contracts with Hardhat:

```sh
yarn compile
```

### Test

Run the tests:

```sh
yarn test
```

#### Test gas costs

To get a report of gas costs, set env `REPORT_GAS` to true

To take a snapshot of the contract's gas costs

```sh
yarn test:gas
```


