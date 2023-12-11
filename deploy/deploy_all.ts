import * as hardhat from "hardhat"
import { DeployFunction } from 'hardhat-deploy/types';


const func: DeployFunction = async function () {

  const { deployments, ethers } = hardhat;
  const { deploy, read, execute, diamond } = deployments;
  const [deployer] = await ethers.getSigners();

  console.log("deployerAddress: ", deployer.address)

  const deployParams = {
    from: deployer.address,
    log: true,
    skipIfAlreadyDeployed: true,
    proxy: {
      owner: deployer.address,
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: "initialize",
          args: []
        }
      }
    },
    args: [] // Never constructor args
  }

  const deployContract = async (contractName: string, skip: boolean = false) =>
    await deploy(contractName, {
      ...deployParams,
      contract: contractName,
      skipIfAlreadyDeployed: skip,
    })

  // Contract Deployments
  const skipDeploy = false;

  const meem = await deployContract("WanderingMerchant", skipDeploy);
  console.log(`deployed Wandering Merchant to ${meem.address}`);

  const squirePotions = await deployContract("SquirePotions", skipDeploy);
  console.log(`deployed SquirePotions to ${squirePotions.address}`);

  const gear = await deployContract("Gear", skipDeploy);
  console.log(`deployed KOTE Gear to ${gear.address}`);

  const squires = await deployContract("KOTESquires", skipDeploy);
  console.log(`deployed KOTE Squires to ${squires.address}`);


  async function setContracts(contract: string, ...args: any[]) {
    await execute(contract, { from: deployer.address, log: true }, `setContracts`, ...args);
  }

  async function setAdmins(contract: string, ...args: any[]) {
    var addressesToAdd = new Array<string>();
    for (var i = 0; i < args.length; i++) {
      let address = args[i];
      if(address === "") {
        continue;
      }
      if (!(await read(contract, `isAdmin`, address))) {
        addressesToAdd.push(address);
      }
    }
    if (addressesToAdd.length > 0) {
      await execute(
        contract,
        { from: deployer.address, log: true },
        `addAdmins`,
        addressesToAdd
      );
    }
  }

  async function unpauseContractIfNeeded(contract: string) {
    if (await read(contract, `paused`)) {
      await execute(contract, { from: deployer.address, log: true }, `setPause`, false);
    }
  }


  // KOTE's actual sepolia addresses
  // const squirePotionsAddress = "0x9867844239bB4Ad2437E4a5c3e9f7992D54cF552"
  // const gearAddress = "0xBA2d18Ec141d01bf1e5fEC9Cbef75193EEdCd06D"
  // const squireAddress = "0xbFfd759b9F7d07ac76797cc13974031Eb23e5757"
  const blessedVillagerAddress = "0xF4b883107140994f79f09E28E16B1b85f1944a8C"

  // Temporary Kote Item contracts for dev purposes
  const squirePotionsAddress = squirePotions.address
  // 0xfc7137e1262424Ad04EFb01cfa31aFc0Ee15dE12
  const gearAddress = gear.address
  // 0xfA535684C4f4666730a7188dc944F4ebB9588837
  const squireAddress = squires.address
  // 0x5714395c32a706B771275A524dD3f347d121b153


  await setContracts(
    "WanderingMerchant",
    squirePotionsAddress,
    gearAddress,
    squireAddress,
    blessedVillagerAddress,
  );

  const teamAdmins: string[] = [
    // Add admin addresses here
  ];

  await setAdmins('WanderingMerchant', ...teamAdmins);
  await setAdmins('KOTESquires', meem.address, ...teamAdmins);
  await setAdmins('Gear', meem.address, ...teamAdmins);

  unpauseContractIfNeeded('WanderingMerchant')
  unpauseContractIfNeeded('KOTESquires')
  unpauseContractIfNeeded('Gear')
  unpauseContractIfNeeded('SquirePotions')

  async function setSquirePotionsAllowedContracts(allowedContracts: string[]) {
    let numAllowedContracts = 0;
    for (let addr of allowedContracts) {
      if (await read("SquirePotions", "checkAllowedContracts", addr)) {
        numAllowedContracts += 1
      }
    }
    if (numAllowedContracts < allowedContracts.length) {
      console.log('setting setAllowedContracts...')
      await execute("SquirePotions", { from: deployer.address, log: true }, "setAllowedContracts", allowedContracts);
    }
  }

  setSquirePotionsAllowedContracts([
    meem.address,
    ...teamAdmins
  ])

}

// hardhat-deploy fixtures
export default func;
func.tags = ['deployments'];


// normal: hardhat deploy function
func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// npx hardhat run --network arbitrumSepolia deploy/deploy_all.ts

// npx hardhat verify --network arbitrumSepolia

// deployed Wandering Merchant to 0x8F6908DE0AB80c5618ac1c9DB0f597c4034cA332
// deployed KOTE Squires to 0x5714395c32a706B771275A524dD3f347d121b153
// deployed KOTE Gear to 0xfA535684C4f4666730a7188dc944F4ebB9588837
// deployed SquirePotions to 0xfc7137e1262424Ad04EFb01cfa31aFc0Ee15dE12

// npx hardhat verify --network arbitrumSepolia 0x8F6908DE0AB80c5618ac1c9DB0f597c4034cA332
// npx hardhat verify --network arbitrumSepolia 0x5714395c32a706B771275A524dD3f347d121b153
// npx hardhat verify --network arbitrumSepolia 0xfA535684C4f4666730a7188dc944F4ebB9588837
// npx hardhat verify --network arbitrumSepolia 0xfc7137e1262424Ad04EFb01cfa31aFc0Ee15dE12

// KoteSquires deployed to: 0xbFfd759b9F7d07ac76797cc13974031Eb23e5757
// Potions deployed to: 0x9867844239bB4Ad2437E4a5c3e9f7992D54cF552
// Trinkets deployed to: 0xa4173e4C04Ed36CaEBDF26783E0CA751c56D6800
// Rings deployed to: 0x14a733278d2C792d1b93DEF58C30CC16AED0DcCD
// Knight gear deployed to: 0xBA2d18Ec141d01bf1e5fEC9Cbef75193EEdCd06D
// Gear bridge deployed to: 0x40dfD822D62B88c0950f2c857b9D8D9BE5d79a18
// Knights deployed to: 0x81829cD23D7fdFA02e4FD8Da2621351eF51A2d23
// BlessedVillagers deployed to: 0xF4b883107140994f79f09E28E16B1b85f1944a8C
// KnightInitiated deployed to: 0x9273607C6CC52003B40E25ce1A64feED71e84DDE
// BlessedVillagerInitiated deployed to: 0x8ad34045e58c3035450cbd281278d243105b0c47
// Crests deployed to: 0x48bd5f104093A6Dbd89eb91ffd646EF63441dE8E
// Sigils deployed to: 0x450210F1f501E94DB0DeA2eD1Cfc880aa803931a
// Initiation deployed to: 0x4b37190fb7F81FafEaea73b968b75116e16A8238