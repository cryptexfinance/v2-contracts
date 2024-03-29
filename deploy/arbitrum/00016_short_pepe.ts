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
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrum") {
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

  const controllerAddress = "0xa59ef0208418559770a48d7ae4f260a28763167b";
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

  if (!process.env.COORDINATOR_ID) {
    console.log("please set COORDINATOR_ID in env");
    return;
  }

  let name = "PEPE Perpetual Market";
  let symbol = "PERPE";

  const productInfo: IProduct.ProductInfoStruct = {
    name: name,
    symbol: symbol,
    payoffDefinition: createPayoffDefinition({short: true }),
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
