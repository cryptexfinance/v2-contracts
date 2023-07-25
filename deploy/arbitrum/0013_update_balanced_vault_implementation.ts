import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Deployment } from "hardhat-deploy/dist/types";
import { hardhatArguments } from "hardhat";
import { BalancedVault__factory, ProxyAdmin__factory } from "../../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

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
  const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer);

  const VAULT_TOKEN_NAME = "TCAP Vault Alpha";
  const VAULT_TOKEN_SYMBOL = "TVA";

  const dsu = "0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b";
  const controller = "0xa59ef0208418559770a48d7ae4f260a28763167b";
  const long = (await get("Product_TCAP_Long")).address;
  const short = (await get("Product_TCAP_Short")).address;
  const targetLeverage = ethers.utils.parseEther("2.5");
  const maxCollateral = ethers.utils.parseEther("3000000");

  const vaultImpl = await deploy("TCAPVaultAlpha_Impl_2", {
    contract: "BalancedVault",
    args: [dsu, controller, long, short, targetLeverage, maxCollateral],
    from: deployer,
    skipIfAlreadyDeployed: true,
    log: true,
    autoMine: true,
  });

  const vaultProxyAddress = (await get("TCAPVaultAlpha_Proxy")).address;

  const proxyAdminAddress = (await get("ProxyAdmin")).address;
  let proxyAdmin = new ProxyAdmin__factory(deployerSigner).attach(
    proxyAdminAddress
  );

  await proxyAdmin.upgrade(vaultProxyAddress, vaultImpl.address);
  console.log("Upgraded vault implementation.");

  const vault = new BalancedVault__factory(deployerSigner).attach(
        vaultProxyAddress
  );
  if ((await vault.name()) === VAULT_TOKEN_NAME) {
    console.log("PerennialVaultAlpha already initialized.");
  } else {
    process.stdout.write("initializing BalancedVaultETH...");
    await (
      await vault.initialize(VAULT_TOKEN_NAME, VAULT_TOKEN_SYMBOL)
    ).wait(2);
  }
};

export default func;
func.tags = ["updateVaultImpl"];
