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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorProxyInterface.sol";


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
    address tcapOracleAddress = address(0x4763b84cdBc5211B9e0a57D5E39af3B3b2440012);
    AggregatorProxyInterface oracle = AggregatorProxyInterface(tcapOracleAddress);


    ERC20PresetMinterPauser usdc = ERC20PresetMinterPauser(usdcAddress);
    ERC20PresetMinterPauser dsu = ERC20PresetMinterPauser(dsuAddress);

    UFixed18 initialCollateral = UFixed18Lib.from(20000);

    address userA = address(0x51);
    address userB = address(0x52);

    function setUp() external {
        vm.deal(userA, 30000 ether);
        vm.deal(userB, 30000 ether);
        deal({token: address(usdc), to: userA, give: UFixed18.unwrap(UFixed18Lib.from(100000000))});
        deal({token: address(usdc), to: userB, give: UFixed18.unwrap(UFixed18Lib.from(100000000))});
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

    function testMakerFees() external {
        uint256 initialTreasuryBalance = UFixed18.unwrap(collateral.fees(cryptexArbitrumTreasury));
        UFixed18 depositAmount = UFixed18Lib.from(10000);
        depositWrapAndDeposit(userA, long, depositAmount);
        assertEq(UFixed18.unwrap(collateral.fees(cryptexArbitrumTreasury)), initialTreasuryBalance);
        vm.prank(userA);
        long.openMake(UFixed18Lib.from(10));
        mockNextOracleUpdate();
        long.settle();
        assertTrue(UFixed18.unwrap(collateral.fees(cryptexArbitrumTreasury)) > initialTreasuryBalance);
    }

    function mockNextOracleUpdate() public {
        (
          uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
        ) = oracle.latestRoundData();
        uint80 nextRoundId = roundId + 1;
        int256 nextAnswer = (answer * 101 / 100);
        uint256 nextStartedAt = startedAt + 1000;
        uint256 nextUpdatedAt = updatedAt + 1000;
        uint80 nextAnsweredInRound = answeredInRound + 1;
        vm.mockCall(
            tcapOracleAddress,
            abi.encodeWithSelector(oracle.latestRoundData.selector),
            abi.encode(
                nextRoundId,
                nextAnswer,
                nextStartedAt,
                nextUpdatedAt,
                nextAnsweredInRound
            )
        );
        vm.mockCall(
            tcapOracleAddress,
            abi.encodeWithSelector(oracle.getRoundData.selector, nextRoundId),
            abi.encode(
                nextRoundId,
                nextAnswer,
                nextStartedAt,
                nextUpdatedAt,
                nextAnsweredInRound
            )
        );
    }

    function wrapUSDCToDSU(address account, UFixed18 amount) public {
        vm.startPrank(userA);
        usdc.approve(address(reserve), UFixed18.unwrap(amount));
        reserve.mint(amount);
        vm.stopPrank();
    }

    function testBalanceVaultClaim() external {
        UFixed18 depositAmount = UFixed18Lib.from(1000);

        wrapUSDCToDSU(userA, depositAmount);
        vm.startPrank(userA);
        dsu.approve(address(vault), UFixed18.unwrap(depositAmount));
        vault.deposit(depositAmount, userA);
        assertEq(
            UFixed18.unwrap(collateral.collateral(address(vault), long)),
            UFixed18.unwrap(collateral.collateral(address(vault), short))
        );
        assertEq(UFixed18.unwrap(vault.maxRedeem(userA)), 0);

        mockNextOracleUpdate();
        vault.sync();

        assertTrue(UFixed18.unwrap(vault.maxRedeem(userA)) > 0);
        vault.redeem(vault.maxRedeem(userA), userA);
        assertEq(UFixed18.unwrap(vault.unclaimed(userA)), 0);

        mockNextOracleUpdate();
        vault.sync();

        assertTrue(UFixed18.unwrap(vault.unclaimed(userA)) > 0);
        vault.claim(userA);
        assertEq(UFixed18.unwrap(vault.unclaimed(userA)), 0);

        vm.stopPrank();
    }
}
