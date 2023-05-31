// run with
// npx hardhat run ./scripts/update_product_params.ts --network arbitrum
import hre, { deployments, network, hardhatArguments } from "hardhat";
import { BigNumber } from "ethers";
import { IProduct__factory, IController__factory } from "../typechain-types";

async function main() {

    const { deployments, getNamedAccounts, ethers } = hre;
    const { deployer } = await getNamedAccounts();
    const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);
    const parseEther = ethers.utils.parseEther;

    const longProductAddress = "0x1cD33f4e6EdeeE8263aa07924c2760CF2EC8aAD0";
	const shortProductAddress = "0x4243b34374cfB0a12f184b92F52035d03d4f7056";
	const controllerAddress = "0xA59eF0208418559770a48D7ae4f260A28763167B";
	const cordinatorID = 2;
    const long = IProduct__factory.connect(longProductAddress, deployerSigner);
    const short = IProduct__factory.connect(shortProductAddress, deployerSigner);
    const controller = IController__factory.connect(controllerAddress, deployerSigner)

    const owner = await controller["owner(uint256)"](cordinatorID);

    console.log(`please make sure that the sender of these transactions is ${owner} \n`)

    // set funding fee to zero
    await long.updateFundingFee(parseEther("0"));
    await short.updateFundingFee(parseEther("0"));
    const newFundingFee = parseEther("0")
    console.log("-".repeat(50), "Transaction 1", "-".repeat(50));
    console.log(`long.updateFundingFee(${newFundingFee});`, `longContractAddress: ${longProductAddress}\n`);
    console.log("-".repeat(50), "Transaction 2", "-".repeat(50));
    console.log(`short.updateFundingFee(${newFundingFee});`, `shortContractAddress: ${shortProductAddress}\n`);


    // change jumprate parameters
    await long.updateUtilizationCurve([parseEther("0.08"), parseEther("1"), parseEther("0.30"), parseEther("0.80")]);
    await short.updateUtilizationCurve([parseEther("0.08"), parseEther("1"), parseEther("0.30"), parseEther("0.80")]);
    const jumpRateParameters = [parseEther("0.08"), parseEther("1"), parseEther("0.30"), parseEther("0.80")];
    console.log("-".repeat(50), "Transaction 3", "-".repeat(50));
    console.log(`long.updateUtilizationCurve(${jumpRateParameters});`, `longContractAddress: ${longProductAddress}\n`);
    console.log("-".repeat(50), "Transaction 4", "-".repeat(50));
    console.log(`short.updateUtilizationCurve(${jumpRateParameters});`, `shortContractAddress: ${shortProductAddress}\n`);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
