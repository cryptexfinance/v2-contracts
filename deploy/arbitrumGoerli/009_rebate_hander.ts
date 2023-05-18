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

  const rebateTokenAddress = "0x912CE59144191C1204E64559FE8253a0e49E6548"
  const owner = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3"
  const maxUsersToClaim = 1000
  const timeElapsedForUpdate = 24 * 60 * 60 // 24 hours
  const timeToReclaimRewards = 3 * 24 * 60 * 60 // 3 days

  const rebateHandler = await deploy("RebateHandler", {
    args: [rebateTokenAddress, owner, maxUsersToClaim, timeElapsedForUpdate, timeToReclaimRewards],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
    autoMine: true,
  });

};

export default func;
func.tags = ["RebateHandler"];
