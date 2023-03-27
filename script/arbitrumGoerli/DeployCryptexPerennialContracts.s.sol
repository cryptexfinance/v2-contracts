// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "@equilibria/perennial/contracts/controller/Controller.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@equilibria/emptyset-batcher/interfaces/IBatcher.sol";

contract DeployCryptex is Script {
//    Token18 DSU = Token18.wrap(address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b));
//    Token6 USDC = Token6.wrap(address(0x6775842AE82BF2F0f987b10526768Ad89d79536E));
    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(address(0x6775842AE82BF2F0f987b10526768Ad89d79536E));
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b));
    IEmptySetReserve reserve = IEmptySetReserve(address(0x0d49c416103Cbd276d9c3cd96710dB264e3A0c27));
    Controller controller = Controller(address(0x6cF1A4373ba7D10bC37fAeC4694807B626B7f161));
    uint256 deployerPrivateKey;
    address deployer;


    function setUp() public {
      deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      deployer = vm.addr(deployerPrivateKey);
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        uint256 coordinatorID = controller.createCoordinator();
        console.log("coordinatorID");
        console.log(coordinatorID);
    }
}
