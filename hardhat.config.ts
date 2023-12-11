import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';

require('@openzeppelin/hardhat-upgrades');
require('hardhat-deploy');
dotenv.config();


const config: HardhatUserConfig = {
  solidity: "0.8.20",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
        allowUnlimitedContractSize: true,
    },
    arbitrumSepolia: {
        url: process.env.ARBITRUM_SEPOLIA_URL || "",
        timeout: 120000,
        live: true,
        saveDeployments: true,
        accounts: process.env.ARB_SEPOLIA_PRIVATE_KEY !== undefined ? [process.env.ARB_SEPOLIA_PRIVATE_KEY] : [],
    },
    arbitrumGoerli: {
        url: process.env.ARBITRUM_GOERLI_URL || "",
        timeout: 120000,
        live: true,
        saveDeployments: true,
        accounts: process.env.ARB_GOERLI_PRIVATE_KEY !== undefined ? [process.env.ARB_GOERLI_PRIVATE_KEY] : [],
    },
    arbitrumMainnet: {
        url: process.env.ARBITRUM_MAINNET_URL || "",
        timeout: 120000,
        live: true,
        saveDeployments: true,
        accounts: process.env.ARBITRUM_MAINNET_PK !== undefined ? [process.env.ARBITRUM_MAINNET_PK] : [],
    },
    localhost: {
      url: "http://localhost:8545",
      chainId : 1337,
    },
  },
  namedAccounts: {
    deployer: 0,
    staker1: 1,
    staker2: 2,
    staker3: 3,
    hacker: 4
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBITRUM_API_KEY
    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io"
        }
      }
    ]
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    coinmarketcap: process.env.COIN_MARKET_CAP,
    gasPriceApi: process.env.GAS_PRICE_API
  }
};

export default config;
