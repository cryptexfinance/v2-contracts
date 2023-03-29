### Cryptex Synthetic Derivatives 
Cryptex Synthetic Derivatives is powered by [perennial](https://github.com/equilibria-xyz/perennial-mono) contracts.

#### Installation
```commandline
curl -L https://foundry.paradigm.xyz | bash
foundryup
git submodule update --init --recursive
yarn install
npx hardhat compile
```

### deploy contracts
```commandline
npx hardhat deploy --network arbitrumGoerli --tags Coordinator
```
set the env var COORDINATOR_ID with the value given by the previous command
```commandline
npx hardhat deploy --network arbitrumGoerli
```