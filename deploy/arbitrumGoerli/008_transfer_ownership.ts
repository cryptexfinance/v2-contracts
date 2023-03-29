import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Deployment } from 'hardhat-deploy/dist/types'
import { hardhatArguments } from "hardhat"
import { IController__factory } from '../../typechain-types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    if (hardhatArguments.network !== "arbitrumGoerli") {
		return
	}

	if(!process.env.COORDINATOR_ID) {
	    console.log("please set COORDINATOR_ID in env");
	    return
	}

    let coordinatorID = parseInt(process.env.COORDINATOR_ID)
    const { deployments, getNamedAccounts, ethers } = hre
    const { deploy, get, getOrNull, getNetworkName } = deployments
    const { deployer } = await getNamedAccounts()
    const deployerSigner: SignerWithAddress = await ethers.getSigner(deployer)

    const controllerAddress = "0x6cF1A4373ba7D10bC37fAeC4694807B626B7f161"
    const controller: IController = IController__factory.connect(controllerAddress, deployerSigner)

    if (deployerSigner.address !== (await controller['owner(uint256)'](coordinatorID))) {
        process.stdout.write('deployer is not owner of coordinatorID... exiting.')
        return
    }

    let cryptexTreasuryAddress = "0x464e8536e552Be1a969d6334D0A317C1e022abbb";
    // set treasury
    let currentTreasuryAddress = await controller.callStatic['treasury(uint256)'](coordinatorID)
    if(currentTreasuryAddress.toLowerCase() !== cryptexTreasuryAddress.toLowerCase()) {
        console.log("updating treasury... ")
        let tx = await controller.updateCoordinatorTreasury(coordinatorID, cryptexTreasuryAddress)
        await tx.wait(2)
        console.log("treasury updated successfully")
    } else {
        console.log("treasury already updated")
    }

    // Uncomment the code below to transfer controller ownership to the multisig or DAO

//     let cryptexMultiSigAddress = "";
//     controller.updateCoordinatorPendingOwner(coordinatorID, cryptexTreasuryAddress);
//     controller.acceptCoordinatorOwner(coordinatorID);


}

export default func
