require("dotenv").config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-dependency-compiler";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "@nomiclabs/hardhat-etherscan";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "hardhat-tracer";


const mnemonic = process.env.DEPLOYER_MNEMONIC as string;
const ganacheMnemonic = process.env.GANACHE_MNEMONIC as string;

const config: HardhatUserConfig = {
    namedAccounts: {
		deployer: {
			default: 0, // here this will by default take the first account as deployer
		},
	},
    solidity: {
		version: "0.8.17",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
    paths: {
      sources: "./contracts",
      cache: "./cache_hardhat",
    },
    dependencyCompiler: {
      paths: [
        '@equilibria/perennial/contracts/interfaces/IController.sol',
        '@equilibria/perennial-oracle/contracts/ChainlinkFeedOracle.sol',
        '@equilibria/perennial-vaults/contracts/BalancedVault.sol',
        '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol',
        '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol',
      ],
    },
    networks: {
		arbitrumGoerli: {
			url: process.env.ARBITRUM_GOERLI_API_URL,
			accounts: { mnemonic: mnemonic },
		},
        arbitrum: {
			url: process.env.ARBITRUM_API_URL,
			accounts: { mnemonic: mnemonic },
		}
	},
};

export default config;
