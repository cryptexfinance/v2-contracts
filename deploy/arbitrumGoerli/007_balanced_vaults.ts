import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Deployment } from 'hardhat-deploy/dist/types'
import { hardhatArguments } from "hardhat"
import { BalancedVault__factory } from '../../typechain-types'


const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    if (hardhatArguments.network !== "arbitrumGoerli") {
		return
	}

    const { deployments, getNamedAccounts, ethers } = hre
    const { deploy, get, getOrNull, getNetworkName } = deployments
    const { deployer } = await getNamedAccounts()
    const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer)

    const VAULT_TOKEN_NAME = 'TCAP Vault Alpha'
    const VAULT_TOKEN_SYMBOL = 'TVA'

    const dsu = "0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b"
    const controller = "0x6cF1A4373ba7D10bC37fAeC4694807B626B7f161"
    const long = (await get('Product_TCAP_Long')).address
    const short = (await get('Product_TCAP_Short')).address
    const targetLeverage = ethers.utils.parseEther('2.5')
    const maxCollateral = ethers.utils.parseEther('3000000')

    const vaultImpl = await deploy('TCAPVaultAlpha_Impl', {
        contract: 'BalancedVault',
        args: [dsu, controller, long, short, targetLeverage, maxCollateral],
        from: deployer,
        skipIfAlreadyDeployed: true,
        log: true,
        autoMine: true,
    })

    const proxyAdminAddress = (await get('ProxyAdmin')).address

    await deploy('TCAPVaultAlpha_Proxy', {
        contract: 'TransparentUpgradeableProxy',
        args: [vaultImpl.address, proxyAdminAddress, '0x'],
        from: deployer,
        skipIfAlreadyDeployed: true,
        log: true,
        autoMine: true,
    })

    const vault = new BalancedVault__factory(deployerSigner).attach((await get('TCAPVaultAlpha_Proxy')).address)
    if ((await vault.name()) === VAULT_TOKEN_NAME) {
        console.log('PerennialVaultAlpha already initialized.')
    } else {
        process.stdout.write('initializing BalancedVaultETH...')
        await (await vault.initialize(VAULT_TOKEN_NAME, VAULT_TOKEN_SYMBOL)).wait(2)
    }
}

export default func
