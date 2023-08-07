import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";
import {
  IController,
  IController__factory,
  IProduct,
} from "../../typechain-types";
import { createPayoffDefinition, reuseOrDeployProduct } from "../../util";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrumGoerli") {
    return;
  }
  if (!process.env.COORDINATOR_ID) {
    console.log("please set COORDINATOR_ID in env");
    return;
  }

  let coordinatorID = parseInt(process.env.COORDINATOR_ID);
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  const controllerAddress = "0x6cF1A4373ba7D10bC37fAeC4694807B626B7f161";
  const controller: IController = IController__factory.connect(
    controllerAddress,
    deployerSigner
  );
  // Check coordinator owner
  if (
    deployerSigner.address !==
    (await controller["owner(uint256)"](coordinatorID))
  ) {
    process.stdout.write(
      "not deploying from coordinator owner address... exiting."
    );
    return;
  }

  let name = "PEPE";
  let symbol = "PEPE";


  const productInfo: IProduct.ProductInfoStruct = {
    name: name,
    symbol: symbol,
    payoffDefinition: createPayoffDefinition(),
    oracle: (await get("PEPEOracle")).address,
    maintenance: ethers.utils.parseEther("0.05"),
    fundingFee: ethers.utils.parseEther("0"),
    makerFee: ethers.utils.parseEther("0"),
    takerFee: ethers.utils.parseEther("0.0015"),
    positionFee: ethers.utils.parseEther("0"),
    makerLimit: ethers.utils.parseEther("3000000"),
    utilizationCurve: {
      minRate: ethers.utils.parseEther("0.2"),
      maxRate: ethers.utils.parseEther("1"),
      targetRate: ethers.utils.parseEther("0.4"),
      targetUtilization: ethers.utils.parseEther("0.8"),
    },
  };

  await reuseOrDeployProduct(
    hre,
    coordinatorID,
    controller,
    productInfo
  );

};

export default func;
func.tags = ["PEPE"];
