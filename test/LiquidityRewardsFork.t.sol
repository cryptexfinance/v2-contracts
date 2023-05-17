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
import "../contracts/LiquidityReward.sol";

contract LiquidityRewardsFork is Test {
    LiquidityReward liquidityReward;
    uint256 coordinatorId = 2;
    Controller controller =
        Controller(0xA59eF0208418559770a48D7ae4f260A28763167B);
    Collateral collateral =
        Collateral(0xAF8CeD28FcE00ABD30463D55dA81156AA5aEEEc2);
    Product long = Product(0x1cD33f4e6EdeeE8263aa07924c2760CF2EC8aAD0);
    Product short = Product(0x4243b34374cfB0a12f184b92F52035d03d4f7056);
    IBalancedVault vault =
        IBalancedVault(0xEa281a4c70Ee2ef5ce3ED70436C81C0863A3a75a);
    address cryptexArbitrumTreasury =
        address(0x9474B771Fb46E538cfED114Ca816A3e25Bb346CF);
    address dsuAddress = address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b);
    address usdcAddress = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address cryptexDeployer =
        address(0xd322a9876222Dea06a478D4a69B75cb83b81Eb3c);
    address ctxAddress = address(0x84F5c2cFba754E76DD5aE4fB369CfC920425E12b);
    IEmptySetReserve reserve =
        IEmptySetReserve(address(0x0d49c416103Cbd276d9c3cd96710dB264e3A0c27));
    MultiInvoker invoker =
        MultiInvoker(address(0xe72E82b672d7D3e206327C0762E9805fbFCBCa92));

    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(usdcAddress);
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(dsu);
    ERC20PresetMinterPauser ctx = ERC20PresetMinterPauser(ctxAddress);

    UFixed18 initialCollateral = UFixed18Lib.from(20000);

    address userA = address(0x173738);
    address userB = address(0x123123);

    function setUp() external {
        vm.deal(userA, 30000 ether);
        deal({
            token: address(usdc),
            to: userA,
            give: 1000 ether
        });

        liquidityReward = new LiquidityReward(
            msg.sender,
            ctxAddress,
            address(vault)
        );
        //deposit to vault
        vm.startPrank(userA);
        usdc.approve(address(invoker), type(uint256).max);
        IMultiInvoker.Invocation[] memory invocations = new IMultiInvoker.Invocation[](1);
        IMultiInvoker.Invocation memory invocation = IMultiInvoker.Invocation({
            action: IMultiInvoker.PerennialAction.VAULT_WRAP_AND_DEPOSIT, //need to update perennial multi invoker as action is not there
            args: abi.encode(userA, address(vault), 1000 ether)
        });
        invocations[0] = invocation;
        invoker.invoke(invocations);
        vm.stopPrank();
        ///should update somehow the values
        UFixed18 amount = vault.balanceOf(userA);
        console.log(usdc.balanceOf(userA));

        console.log(UFixed18.unwrap(amount));
    }

    function testStake_ShouldTransferShares() public {
        //setUp
        UFixed18 amount = vault.balanceOf(userA);
        vm.startPrank(userA);
        //execution
        vault.approve(address(liquidityReward), amount);
        liquidityReward.stake(UFixed18.unwrap(amount));
        //assert
        assertTrue(vault.balanceOf(userA).eq(UFixed18Lib.from(0)));
        assertEq(liquidityReward.balanceOf(userA), (UFixed18.unwrap(amount)));
        assertTrue(vault.balanceOf(address(liquidityReward)).eq(amount));
        assertTrue(!vault.balanceOf(address(liquidityReward)).eq(UFixed18Lib.from(0)));
    }

    function testWithdraw_ShouldTransferBackShares() public {
        //setUp
        UFixed18 amount = vault.balanceOf(userA);
        vm.startPrank(userA);
        vault.approve(address(liquidityReward), amount);
        liquidityReward.stake(UFixed18.unwrap(amount));
        //execution
        liquidityReward.withdraw(UFixed18.unwrap(amount));
        //assert
        assertTrue(vault.balanceOf(userA).eq(amount));
        assertEq(liquidityReward.balanceOf(userA), 0);
        assertTrue(
            vault.balanceOf(address(liquidityReward)).eq(UFixed18Lib.from(0))
        );
         assertTrue(!vault.balanceOf(address(liquidityReward)).eq(UFixed18Lib.from(0)));
    }

    function testStake_ShouldAccrueRewards_WhenTimePasses() public {
        deal({
            token: address(ctx),
            to: userA,
            give: 30000 ether
        });
        vm.startPrank(userA);
        ctx.transfer(address(liquidityReward), 30000 ether);
        UFixed18 amount = vault.balanceOf(userA);
        vault.approve(address(liquidityReward), amount);
        liquidityReward.stake(UFixed18.unwrap(amount));
        assert(vault.balanceOf(userA).eq(UFixed18Lib.from(0)));
        assert(vault.balanceOf(address(liquidityReward)).eq(amount));
        assertTrue(liquidityReward.earned(userA) == 0);
        vm.stopPrank();
        //execution
        vm.prank(msg.sender);
        liquidityReward.notifyRewardAmount(30000 ether);
        skip(3600);
        uint256 oldEarned = liquidityReward.earned(userA);
        skip(3600);
        uint256 earned = liquidityReward.earned(userA);
        assert(earned > oldEarned);
        vm.prank(userA);
        liquidityReward.exit();
        assertEq(liquidityReward.earned(userA), 0);
        assertTrue(
            vault.balanceOf(address(liquidityReward)).eq(UFixed18Lib.from(0))
        );
        assertTrue(vault.balanceOf(userA).eq(amount));
    }
}
