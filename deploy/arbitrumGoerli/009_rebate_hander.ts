import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrumGoerli") {
    return;
  }

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  const rebateTokenAddress = "0x6775842AE82BF2F0f987b10526768Ad89d79536E";
  const owner = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3";
  // Please make sure that owner!=merkleRootAdmin on mainnet
  const merkleRootAdmin = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3";
  const maxUsersToClaim = 50;
  const timeElapsedForUpdate = 24 * 60 * 60; // 24 hours
  const timeToReclaimRewards = 3 * 24 * 60 * 60; // 3 days

  const rebateHandler = await deploy("RebateHandler", {
    args: [
      rebateTokenAddress,
      owner,
      merkleRootAdmin,
      maxUsersToClaim,
      timeElapsedForUpdate,
      timeToReclaimRewards,
    ],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
    autoMine: true,
  });
};

export default func;
func.tags = ["RebateHandler"];
