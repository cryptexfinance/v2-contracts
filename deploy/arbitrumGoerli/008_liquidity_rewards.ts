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

  const rewardToken = "0x6775842AE82BF2F0f987b10526768Ad89d79536E";
  let stakingToken = (await get("TCAPVaultAlpha_Proxy")).address;
  let cryptexMultisigAddress = "0xEA8b3DF14B0bad2F6DD0Ed847DCc54Fc100e40C3";

  await deploy("LiquidityReward", {
    contract: "LiquidityReward",
    args: [cryptexMultisigAddress,rewardToken,stakingToken],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
func.tags = ["LiquidityRewards"];
