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

  const rewardToken = "0x84F5c2cFba754E76DD5aE4fB369CfC920425E12b";
  let stakingToken = "0xEa281a4c70Ee2ef5ce3ED70436C81C0863A3a75a";
  let cryptexMultisigAddress = "0x8705b41F9193f05ba166a1D5C0771E9cB2Ca0aa3";

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
