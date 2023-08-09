// run with
// npx hardhat run ./scripts/update_pepe_maker_limit.ts --network arbitrum
import hre, { deployments, network, hardhatArguments } from "hardhat";
import { IProduct__factory, IController__factory } from "../typechain-types";

async function main() {

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  const makerLimit = ethers.utils.parseEther("60000000000000");
  const longAddress = (await get("Product_PEPE_Long")).address;
  const shortAddress = (await get("Product_PEPE_Short")).address;
  const long = IProduct__factory.connect(longAddress, deployerSigner);
  const short = IProduct__factory.connect(shortAddress, deployerSigner);

  console.log("Old makerLimit for the long product is", await long.makerLimit());
  console.log("Old makerLimit for the Short product is", await short.makerLimit());
  let tx = await long.updateMakerLimit(makerLimit);
  await tx.wait();
  tx = await short.updateMakerLimit(makerLimit);
  await tx.wait();
  console.log("New makerLimit for the long product is", await long.makerLimit());
  console.log("New makerLimit for the short product is", await short.makerLimit());

}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
