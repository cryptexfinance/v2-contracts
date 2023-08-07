import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrum") {
    return;
  }

  if (!process.env.COORDINATOR_ID) {
    console.log("please set COORDINATOR_ID in env");
    return;
  }

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();

  const tcapOracleDeployment = "0x4763b84cdBc5211B9e0a57D5E39af3B3b2440012"

  await deploy("TcapOracle", {
    contract: "ChainlinkFeedOracle",
    args: [tcapOracleDeployment],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
