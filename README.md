## Meem-as-a-service

Add your .env file then run this to deploy to arbitrum sepolia:
```
npx hardhat run --network arbitrumSepolia deploy/deploy_all.ts
```

Then run this to verify the contracts + link proxies with implementation contracts when upgrading
```
npx hardhat verify --network arbitrumSepolia <address>
```

## Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run deploy/deploy_all.ts
```
