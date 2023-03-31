import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { hardhatArguments } from "hardhat";
import { IController, IController__factory } from "../../typechain-types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrum") {
    return;
  }
  let coordinatorID = process.env.COORDINATOR_ID;
  const { deployments, getNamedAccounts, ethers } = hre;
  const { get } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  // Load
  const controllerAddress = "0xa59ef0208418559770a48d7ae4f260a28763167b";
  const controller: IController = IController__factory.connect(
    controllerAddress,
    deployerSigner
  );
  const nextControllerId = await controller.callStatic.createCoordinator();

  // Run
  if (process.env.COORDINATOR_ID) {
    console.log(`coordinator with id ${coordinatorID} already created.`);
  } else {
    if(deployerSigner){

    }
    process.stdout.write("creating coordinator... ");
    let tx = await controller.createCoordinator();
    await tx.wait(2);
    let receipt = await deployerSigner.provider?.getTransactionReceipt(tx.hash);
    let id;
    if(receipt){
        id = await controller.callStatic.createCoordinator({
            blockTag: receipt.blockNumber - 1,
          });
    }
    console.log(
      `created coordinator with ID = ${id}. Please set this value in .env for COORDINATOR_ID`
    );
  }
};

export default func;
func.tags = ["Coordinator"];
