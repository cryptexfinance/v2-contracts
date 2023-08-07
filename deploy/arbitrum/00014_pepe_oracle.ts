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

  const pepeOracleAddress = "0x02DEd5a7EDDA750E3Eb240b54437a54d57b74dBE"

  await deploy("PEPEOracle", {
    contract: "ChainlinkFeedOracle",
    args: [pepeOracleAddress],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
  });
};

export default func;
func.tags = ["PEPE"];
