// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@equilibria/perennial/contracts/collateral/Collateral.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@equilibria/emptyset-batcher/interfaces/IBatcher.sol";

contract MintDSU is Script {
    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(address(0x6775842AE82BF2F0f987b10526768Ad89d79536E));
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b));
    IEmptySetReserve reserve = IEmptySetReserve(address(0x0d49c416103Cbd276d9c3cd96710dB264e3A0c27));
    uint256 deployerPrivateKey;
    address deployer;


    function setUp() public {
      deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      deployer = vm.addr(deployerPrivateKey);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        usdc.mint(deployer, 10 ether);
        usdc.approve(address(reserve), 1 ether);
        reserve.mint(UFixed18Lib.from(100000));
    }
}
