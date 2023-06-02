// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@equilibria/perennial/contracts/collateral/Collateral.sol";
import "@equilibria/perennial/contracts/controller/Controller.sol";
import "@equilibria/perennial/contracts/product/Product.sol";
import "@equilibria/perennial-vaults/contracts/interfaces/IBalancedVault.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@equilibria/perennial/contracts/multiinvoker/MultiInvoker.sol";

import "../contracts/mocks/ChainlinkTCAPAggregatorV3.sol";
import "../contracts/LiquidityReward.sol";


contract TCAPPerennialForkTest is Test {

    uint256 coordinatorId =  15;
    Controller controller = Controller(0xA59eF0208418559770a48D7ae4f260A28763167B);
    Collateral collateral = Collateral(0xAF8CeD28FcE00ABD30463D55dA81156AA5aEEEc2);
    Product long = Product(0xe86E16804CC7386bcdd36755C2115601B356dA92);
    Product short = Product(0x18a0A5fBEFca5362D2A279e0819195C10361a03c);
    IBalancedVault vault = IBalancedVault(0xE4c55aad5b60f0C1983De54f00D28Fc887abc472);
    address dsuAddress = address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b);
    address usdcAddress = address(0x6775842AE82BF2F0f987b10526768Ad89d79536E);
    address cryptexDeployer = address(0xd322a9876222Dea06a478D4a69B75cb83b81Eb3c);
    IEmptySetReserve reserve =
        IEmptySetReserve(address(0x0d49c416103Cbd276d9c3cd96710dB264e3A0c27));
    MultiInvoker invoker =
        MultiInvoker(address(0xe72E82b672d7D3e206327C0762E9805fbFCBCa92));
    ChainlinkTCAPAggregatorV3 oracle = ChainlinkTCAPAggregatorV3(0x4B7C73d46f2ECaa76127b4F2304a4FaF5c47F66A);

    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(usdcAddress);
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(dsuAddress);
    LiquidityReward lReward = LiquidityReward(0x393024Ba0ECB3a684C9D0bc2BC023B8DD9Ed21c1);

    UFixed18 initialCollateral = UFixed18Lib.from(20000);

    address userA = address(0x51);
    address userB = address(0x52);

    function testVaultDeposit() external {
        oracle.next();
        vm.startPrank(userA);
        usdc.mint(userA, 100 ether);
        dsu.approve(address(vault), 100 ether);
        usdc.approve(address(reserve), 100 ether);
        reserve.mint(UFixed18Lib.from(100000));
        vault.deposit(UFixed18Lib.from(1), userA);
        assertEq(UFixed18.unwrap(vault.balanceOf(userA)), 0);
        oracle.next();
        vault.sync();
        uint256 _balance = UFixed18.unwrap(vault.balanceOf(userA));
        assertTrue(_balance > 0);
        vault.approve(address(lReward), UFixed18Lib.from(_balance));
        lReward.stake(_balance);
        assertEq(UFixed18.unwrap(vault.balanceOf(userA)), 0);
        vm.stopPrank();
    }
}
