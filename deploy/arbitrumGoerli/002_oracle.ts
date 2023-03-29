import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (hardhatArguments.network !== "arbitrumGoerli") {
    return;
  }

  if (!process.env.COORDINATOR_ID) {
    console.log("please set COORDINATOR_ID in env");
    return;
  }

  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, get, getOrNull, getNetworkName } = deployments;
  const { deployer } = await getNamedAccounts();
  // Note: This will be the Oracle address on mainnet. No need to deploy.
  const tcapOracleDeployment = await deploy("ChainlinkTCAPAggregatorV3", {
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
    autoMine: true,
  });

  await deploy("TcapOracle", {
    contract: "ChainlinkFeedOracle",
    args: [tcapOracleDeployment.address],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
