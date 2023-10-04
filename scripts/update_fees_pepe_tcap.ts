// run with
// npx hardhat run ./scripts/update_fees_pepe_tcap.ts --network arbitrum
import hre, { deployments, network, hardhatArguments } from "hardhat";
import { IProduct__factory, IController__factory } from "../typechain-types";

async function main() {

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  const tcapLongAddress = (await get("Product_TCAP_Long")).address;
  const tcapShortAddress = (await get("Product_TCAP_Short")).address;
  const tcapLong = IProduct__factory.connect(tcapLongAddress, deployerSigner);
  const tcapShort = IProduct__factory.connect(tcapShortAddress, deployerSigner);

  const pepeLongAddress = (await get("Product_PERPE_Long")).address;
  const pepeShortAddress = (await get("Product_PERPE_Short")).address;
  const pepeLong = IProduct__factory.connect(pepeLongAddress, deployerSigner);
  const pepeShort = IProduct__factory.connect(pepeShortAddress, deployerSigner);

  const newMakerfee = ethers.utils.parseEther("0.002125")
  const newTakerfee = ethers.utils.parseEther("0.002125")
  const newPositionFee = ethers.utils.parseEther("1")

  console.log("Old makerFee for TCAP long product is", await tcapLong.makerFee());
  console.log("Old makerFee for TCAP Short product is", await tcapShort.makerFee());
  console.log("Old takerFee for TCAP long product is", await tcapLong.takerFee());
  console.log("Old takerFee for TCAP Short product is", await tcapShort.takerFee());
  let tx = await tcapLong.updateMakerFee(newMakerfee);
  await tx.wait();
  tx = await tcapShort.updateMakerFee(newMakerfee);
  await tx.wait();
  tx = await tcapLong.updateTakerFee(newTakerfee);
  await tx.wait();
  tx = await tcapShort.updateTakerFee(newTakerfee);
  await tx.wait();
  console.log("New makerFee for TCAP long product is", await tcapLong.makerFee());
  console.log("New makerFee for TCAP Short product is", await tcapShort.makerFee());
  console.log("New takerFee for TCAP long product is", await tcapLong.takerFee());
  console.log("New takerFee for TCAP Short product is", await tcapShort.takerFee());

  console.log("Old positionFee for PERPE long product is", await pepeLong.positionFee());
  console.log("Old positionFee for PERPE Short product is", await pepeShort.positionFee());
  tx = await pepeLong.updatePositionFee(newPositionFee)
  await tx.wait();
  tx = await pepeShort.updatePositionFee(newPositionFee)
  await tx.wait();
  console.log("New positionFee for PERPE long product is", await pepeLong.positionFee());
  console.log("New positionFee for PERPE Short product is", await pepeShort.positionFee());

  console.log("Old makerFee for PERPE long product is", await pepeLong.makerFee());
  console.log("Old makerFee for PERPE Short product is", await pepeShort.makerFee());
  console.log("Old takerFee for PERPE long product is", await pepeLong.takerFee());
  console.log("Old takerFee for PERPE Short product is", await pepeShort.takerFee());
  tx = await pepeLong.updateMakerFee(newMakerfee);
  await tx.wait();
  tx = await pepeShort.updateMakerFee(newMakerfee);
  await tx.wait();
  tx = await pepeLong.updateTakerFee(newTakerfee);
  await tx.wait();
  tx = await pepeShort.updateTakerFee(newTakerfee);
  await tx.wait();
  console.log("New makerFee for PERPE long product is", await pepeLong.makerFee());
  console.log("New makerFee for PERPE Short product is", await pepeShort.makerFee());
  console.log("New takerFee for PERPE long product is", await pepeLong.takerFee());
  console.log("New takerFee for PERPE Short product is", await pepeShort.takerFee());
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
