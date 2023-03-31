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

  let name = "Total Market Cap";
  let symbol = "TCAP";

  let payoffProviderAddress = (await get("TcapPayoffProvider")).address;

  const productInfo: IProduct.ProductInfoStruct = {
    name: name,
    symbol: symbol,
    payoffDefinition: createPayoffDefinition({
      contractAddress: payoffProviderAddress,
    }),
    oracle: (await get("TcapOracle")).address,
    maintenance: ethers.utils.parseEther("0.10"),
    fundingFee: ethers.utils.parseEther("0.05"),
    makerFee: ethers.utils.parseEther("0.15"),
    takerFee: ethers.utils.parseEther("0.15"),
    positionFee: ethers.utils.parseEther("1"),
    makerLimit: ethers.utils.parseEther("4000"),
    utilizationCurve: {
      minRate: ethers.utils.parseEther("0.00"),
      maxRate: ethers.utils.parseEther("0.80"),
      targetRate: ethers.utils.parseEther("0.06"),
      targetUtilization: ethers.utils.parseEther("0.80"),
    },
  };

  await reuseOrDeployProduct(
    hre,
    coordinatorID,
    controller,
    productInfo
  );

  // TODO: transfer ownership to Multisig
};

export default func;
