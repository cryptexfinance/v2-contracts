import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { hardhatArguments } from "hardhat";
import { IController__factory } from "../../typechain-types";

const EXAMPLE_COORDINATOR_ID = 1;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrumGoerli") {
    return;
  }
  let coordinatorID = process.env.COORDINATOR_ID;
  const { deployments, getNamedAccounts, ethers } = hre;
  const { get } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  // Load
  const controllerAddress = "0x6cF1A4373ba7D10bC37fAeC4694807B626B7f161";
  const controller: IController = IController__factory.connect(
    controllerAddress,
    deployerSigner
  );
  const nextControllerId = await controller.callStatic.createCoordinator();

  // Run
  if (process.env.COORDINATOR_ID) {
    console.log(`coordinator with id ${coordinatorID} already created.`);
  } else {
    process.stdout.write("creating coordinator... ");
    let tx = await controller.createCoordinator();
    await tx.wait(2);
    let receipt = await deployerSigner.provider.getTransactionReceipt(tx.hash);
    coordinatorID = await controller.callStatic.createCoordinator({
      blockTag: receipt.blockNumber - 1,
    });
    console.log(
      `created coordinator with ID = ${coordinatorID}. Please set this value in .env for COORDINATOR_ID`
    );
  }
};

export default func;
func.tags = ["Coordinator"];
