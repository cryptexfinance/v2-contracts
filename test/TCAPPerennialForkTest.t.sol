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


contract TCAPPerennialForkTest is Test {

    uint256 coordinatorId =  2;
    Controller controller = Controller(0xA59eF0208418559770a48D7ae4f260A28763167B);
    Collateral collateral = Collateral(0xAF8CeD28FcE00ABD30463D55dA81156AA5aEEEc2);
    Product long = Product(0x1cD33f4e6EdeeE8263aa07924c2760CF2EC8aAD0);
    Product short = Product(0x4243b34374cfB0a12f184b92F52035d03d4f7056);
    IBalancedVault vault = IBalancedVault(0xEa281a4c70Ee2ef5ce3ED70436C81C0863A3a75a);
    address cryptexArbitrumTreasury = address(0x9474B771Fb46E538cfED114Ca816A3e25Bb346CF);
    address dsuAddress = address(0x52C64b8998eB7C80b6F526E99E29ABdcC86B841b);
    address usdcAddress = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address cryptexDeployer = address(0xd322a9876222Dea06a478D4a69B75cb83b81Eb3c);
    IEmptySetReserve reserve =
        IEmptySetReserve(address(0x0d49c416103Cbd276d9c3cd96710dB264e3A0c27));
    MultiInvoker invoker =
        MultiInvoker(address(0xe72E82b672d7D3e206327C0762E9805fbFCBCa92));

    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(usdcAddress);
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(dsu);

    UFixed18 initialCollateral = UFixed18Lib.from(20000);

    address userA = address(0x51);
    address userB = address(0x52);

    function setUp() external {
        vm.deal(userA, 30000 ether);
        vm.deal(userB, 30000 ether);
        deal({token: address(usdc), to: userA, give: UFixed18.unwrap(UFixed18Lib.from(100000))});
        deal({token: address(usdc), to: userB, give: UFixed18.unwrap(UFixed18Lib.from(100000))});
    }

    function testSetup() external {
        assertEq(controller.treasury(coordinatorId), cryptexArbitrumTreasury);
        assertEq(controller.coordinatorFor(long), coordinatorId);
        assertEq(controller.coordinatorFor(short), coordinatorId);
        assertEq(controller.treasury(long), cryptexArbitrumTreasury);
        assertEq(controller.treasury(short), cryptexArbitrumTreasury);
        assertEq(controller.owner(long), cryptexDeployer);
        assertEq(controller.owner(short), cryptexDeployer);
    }

    function depositWrapAndDeposit(
        address account,
        IProduct _product,
        UFixed18 amount
    ) public {
        vm.startPrank(account);
        usdc.approve(address(invoker), type(uint256).max);
        IMultiInvoker.Invocation[] memory invocations = new IMultiInvoker.Invocation[](1);
        IMultiInvoker.Invocation memory invocation = IMultiInvoker.Invocation({
            action: IMultiInvoker.PerennialAction.WRAP_AND_DEPOSIT,
            args: abi.encode(account, _product, amount)
        });
        invocations[0] = invocation;
        invoker.invoke(invocations);
        vm.stopPrank();
    }

    function testDeposit() external {
        UFixed18 depositAmount = UFixed18Lib.from(10);
        depositWrapAndDeposit(userA, long, depositAmount);
        assertEq(UFixed18.unwrap(collateral.collateral(userA, long)), UFixed18.unwrap(depositAmount));
        depositWrapAndDeposit(userA, short, depositAmount);
        assertEq(UFixed18.unwrap(collateral.collateral(userA, short)), UFixed18.unwrap(depositAmount));
    }

    function testOpenMake() external {
        UFixed18 depositAmount = UFixed18Lib.from(10);
        depositWrapAndDeposit(userA, long, depositAmount);
        depositWrapAndDeposit(userA, short, depositAmount);
        vm.startPrank(userA);
        long.openMake(UFixed18Lib.from(1));
        short.openMake(UFixed18Lib.from(1));
        vm.stopPrank();
    }

    function testOpenTake() external {
        UFixed18 depositAmount = UFixed18Lib.from(20);
        depositWrapAndDeposit(userA, long, depositAmount);
        depositWrapAndDeposit(userB, long, depositAmount);
        vm.prank(userA);
        long.openMake(UFixed18Lib.from(2));
        vm.prank(userB);
        long.openTake(UFixed18Lib.from(1));
    }

    function testUpdateParams() external {
        address owner = controller.owner(coordinatorId);
        vm.startPrank(owner);
        long.updateFundingFee(UFixed18Lib.from(0));
        short.updateFundingFee(UFixed18Lib.from(0));
        assertTrue(long.fundingFee().eq(UFixed18Lib.from(0)));
        assertTrue(short.fundingFee().eq(UFixed18Lib.from(0)));

        long.updateUtilizationCurve(JumpRateUtilizationCurve({
                minRate: Fixed18Lib.from(int256(8)).div(Fixed18Lib.from(int256(100))).pack(),
                maxRate: Fixed18Lib
                    .from(int256(100))
                    .div(Fixed18Lib.from(int256(100)))
                    .pack(),
                targetRate: Fixed18Lib
                    .from(int256(30))
                    .div(Fixed18Lib.from(int256(100)))
                    .pack(),
                targetUtilization: UFixed18Lib
                    .from(80)
                    .div(UFixed18Lib.from(100))
                    .pack()
            }));
        short.updateUtilizationCurve(JumpRateUtilizationCurve({
                minRate: Fixed18Lib.from(int256(8)).div(Fixed18Lib.from(int256(100))).pack(),
                maxRate: Fixed18Lib
                    .from(int256(100))
                    .div(Fixed18Lib.from(int256(100)))
                    .pack(),
                targetRate: Fixed18Lib
                    .from(int256(30))
                    .div(Fixed18Lib.from(int256(100)))
                    .pack(),
                targetUtilization: UFixed18Lib
                    .from(80)
                    .div(UFixed18Lib.from(100))
                    .pack()
            }));
        JumpRateUtilizationCurve memory longUtilizationCurve = long.utilizationCurve();
        JumpRateUtilizationCurve memory shortUtilizationCurve = short.utilizationCurve();
        assertTrue(
            longUtilizationCurve.minRate.unpack().eq(Fixed18Lib.from(int256(8)).div(Fixed18Lib.from(int256(100))))
        );
        assertTrue(
            shortUtilizationCurve.minRate.unpack().eq(Fixed18Lib.from(int256(8)).div(Fixed18Lib.from(int256(100))))
        );
    }
}
