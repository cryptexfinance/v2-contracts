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
  const deployerSigner = await ethers.getSigner(deployer);

  const rewardTokenAddress = "0x6775842AE82BF2F0f987b10526768Ad89d79536E"; // CTX Token
  const owner = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3"; // Arbitrum Multisig
  // Please make sure that owner!=merkleRootAdmin on mainnet
  const merkleRootAdmin = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3";
  const timeElapsedForUpdate = 30 * 24 * 60 * 60; // 30 days to update rewards
  const timeToReclaimRewards = 60 * 24 * 60 * 60; // 60 days for Multisig to claim rewards

  const referralHandler = await deploy("ReferralHandler", {
    contract:"ReferralHandler",
    args: [
        rewardTokenAddress,
      owner,
      merkleRootAdmin,
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
func.tags = ["ReferralHandler"];
