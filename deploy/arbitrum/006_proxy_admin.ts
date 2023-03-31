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
  // Note: This will be the Oracle address on mainnet. No need to deploy.
  const tcapOracleDeployment = await deploy("ProxyAdmin", {
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
    autoMine: true,
  });
  // TODO: transfer ownership to Multisig
};

export default func;
