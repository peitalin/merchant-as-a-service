import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Utilities } from "../utilities/utilities";
import { deployments, ethers } from "hardhat"
import { SquirePotions, WanderingMerchant } from "../typechain-types";


describe("WanderingMerchant", function () {
    let _ownerWallet: SignerWithAddress;
    let _otherWallet: SignerWithAddress;

    let squirePotions: SquirePotions;
    let wanderingMerchant: WanderingMerchant;

    beforeEach(async () => {
        Utilities.changeAutomineEnabled(true);

        // TODO: need to get hardhat-deploy fixtures working for tests
        await deployments.fixture(['deployments'], { fallbackToGlobal: false });
        wanderingMerchant = await Utilities.getDeployedContract<WanderingMerchant>('WanderingMerchant', _ownerWallet);
        squirePotions = await Utilities.getDeployedContract<SquirePotions>('SquirePotions', _ownerWallet);

    });


    it("Should be able to add a recipe", async function () {
        await(await wanderingMerchant.addRecipes([
            {
                currentAvailable: 10,
                maxAvailable: 10,
                inputType: 0,
                inputTokenId: 1,
                inputAmount: 1,
                outputs: [
                    {
                        outputType: 0,
                        transferredFrom: ethers.ZeroAddress,
                        tokenId: 2,
                        amount: 1,
                        outputAddress: ethers.ZeroAddress
                    }
                ]
            }
        ])).wait();
    });

    it("Should not be able to fulfill a recipe when the merchant is not open", async function () {
        await expect(wanderingMerchant.fulfillRecipes([
            {
                recipeId: 1,
                inputTokenId: 1
            }
        ])).to.be.revertedWith("Merchant is not open");

        await(await wanderingMerchant.openMerchant(
            1,
            2,
            true,
            [
                {
                    currentAvailable: 10,
                    maxAvailable: 10,
                    inputType: 0,
                    inputTokenId: 1,
                    inputAmount: 1,
                    outputs: [
                        {
                            outputType: 0,
                            transferredFrom: ethers.ZeroAddress,
                            tokenId: 2,
                            amount: 1,
                            outputAddress: ethers.ZeroAddress
                        }
                    ]
                }
            ]
        )).wait();

        // Passed close time
        //
        await expect(wanderingMerchant.fulfillRecipes([
            {
                recipeId: 1,
                inputTokenId: 1
            }
        ])).to.be.revertedWith("Merchant is not open");
    });

    it("Should be able to fulfill a recipe when the merchant is open", async function () {
        const openTime = await Utilities.blockNow();
        const closeTime = openTime.add(1000);
        await(await wanderingMerchant.openMerchant(
            openTime,
            closeTime,
            true,
            [
                {
                    currentAvailable: 10,
                    maxAvailable: 10,
                    inputType: 0, // Squire Potions
                    inputTokenId: 1,
                    inputAmount: 1,
                    outputs: [
                        {
                            outputType: 0, // Squire Potions
                            transferredFrom: ethers.ZeroAddress,
                            tokenId: 2,
                            amount: 1,
                            outputAddress: ethers.ZeroAddress
                        }
                    ]
                }
            ]
        )).wait();

        await(await squirePotions.mint(_ownerWallet.address, 1)).wait();

        // Passed close time
        //
        await(await wanderingMerchant.fulfillRecipes([
            {
                recipeId: 1,
                inputTokenId: 1
            }
        ])).wait();

        expect(await squirePotions.balanceOf(_ownerWallet.address, 2))
            .to.eq(1);
    });
}).timeout(100000);
