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

  const rebateTokenAddress = "0x912ce59144191c1204e64559fe8253a0e49e6548"; // ARB Token
  const owner = "0x8705b41F9193f05ba166a1D5C0771E9cB2Ca0aa3"; // Arbitrum Multisig
  // Please make sure that owner!=merkleRootAdmin on mainnet
  const merkleRootAdmin = "0xE7A4B3A6db8607Ebc8407f739a1D0D6A3167Bb94";
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
