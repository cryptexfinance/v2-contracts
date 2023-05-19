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

  const rewardToken = "0x874a0269bbe3fa8b8ebb2be15dac2142843eeeeb";
  let stakingToken = (await get("TCAPVaultAlpha_Proxy")).address;
  let cryptexMultisigAddress = "0x464e8536e552Be1a969d6334D0A317C1e022abbb";

  await deploy("LiquidityReward", {
    contract: "LiquidityReward",
    args: [cryptexMultisigAddress,rewardToken,stakingToken],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;