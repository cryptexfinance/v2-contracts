import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrum") {
    return;
  }

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  const deployerSigner = await ethers.getSigner(deployer);

  const rewardTokenAddress = "0x84F5c2cFba754E76DD5aE4fB369CfC920425E12b"; // CTX Token
  const owner = "0x8705b41F9193f05ba166a1D5C0771E9cB2Ca0aa3"; // Arbitrum Multisig
  // Please make sure that owner!=merkleRootAdmin on mainnet
  const merkleRootAdmin = "0xE7A4B3A6db8607Ebc8407f739a1D0D6A3167Bb94";
  const timeElapsedForUpdate = 28 * 24 * 60 * 60; // 28 days to update rewards
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
