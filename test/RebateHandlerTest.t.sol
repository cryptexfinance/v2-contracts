// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../contracts/RebateHandler.sol";

contract RebateHandlerTest is Test {
    ERC20 rebateToken;
    RebateHandler rebateHandler;

    event MerkleRootUpdated(bytes32 merkleRoot, uint256 maxAmountToClaim);
    event RewardPaid(address indexed user, uint256 reward);

    address owner = address(0x51);
    address user1 = address(0x1111111111111111111111111111111111111111);
    address user2 = address(0x2222222222222222222222222222222222222222);
    address user3 = address(0x3333333333333333333333333333333333333333);
    address[3] users = [user1, user2, user3];

    //    tree = StandardMerkleTree.of([
    //        ["0x1111111111111111111111111111111111111111", "5000000000000000000"],
    //        ["0x2222222222222222222222222222222222222222", "2500000000000000000"],
    //        ["0x3333333333333333333333333333333333333333", "3300000000000000000"]
    //    ],
    //        ["address", "uint256"]
    //    )
    //    root = 0xc9e7f2e4ab24ce3b1f63ec4fd987c4a864e18ab41c2744100a356203d9f955df
    //    tree.getProof(
    //        ["0x1111111111111111111111111111111111111111", "5000000000000000000"]
    //    ) = [ "0xb8d3cd33d72346f46c8110c577b6fd36543cacb3ec052a2cb22a69315267c81a" ]
    //    tree.getProof(
    //        ['0x2222222222222222222222222222222222222222', '2500000000000000000']
    //    ) = [
    //      '0xe8e600fa2a2b1a74022e7827267c3a5beddaf6113177a1f461084bdaf969002c',
    //      '0xeb02c421cfa48976e66dfb29120745909ea3a0f843456c263cf8f1253483e283'
    //    ]
    //    tree.getProof(
    //            ['0x3333333333333333333333333333333333333333', '3300000000000000000']
    //    ) = [
    //      '0xb92c48e9d7abe27fd8dfd6b5dfdbfb1c9a463f80c712b66f3a5180a090cccafc',
    //      '0xeb02c421cfa48976e66dfb29120745909ea3a0f843456c263cf8f1253483e283'
    //    ]
    bytes32 merkleRoot1 =
        bytes32(
            0xc9e7f2e4ab24ce3b1f63ec4fd987c4a864e18ab41c2744100a356203d9f955df
        );
    bytes32[] proof1User1 = [
        bytes32(
            0xb8d3cd33d72346f46c8110c577b6fd36543cacb3ec052a2cb22a69315267c81a
        )
    ];
    bytes32[] proof1User2 = [
        bytes32(
            0xe8e600fa2a2b1a74022e7827267c3a5beddaf6113177a1f461084bdaf969002c
        ),
        bytes32(
            0xeb02c421cfa48976e66dfb29120745909ea3a0f843456c263cf8f1253483e283
        )
    ];
    bytes32[] proof1User3 = [
        bytes32(
            0xb92c48e9d7abe27fd8dfd6b5dfdbfb1c9a463f80c712b66f3a5180a090cccafc
        ),
        bytes32(
            0xeb02c421cfa48976e66dfb29120745909ea3a0f843456c263cf8f1253483e283
        )
    ];
    uint256 amount1User1 = 5000000000000000000;
    uint256 amount1User2 = 2500000000000000000;
    uint256 amount1User3 = 3300000000000000000;

    //    tree = StandardMerkleTree.of([
    //        ["0x1111111111111111111111111111111111111111", "5500000000000000000"],
    //        ["0x2222222222222222222222222222222222222222", "10000000000000000000"],
    //        ["0x3333333333333333333333333333333333333333", "93200000000000000000"]
    //    ],
    //        ["address", "uint256"]
    //    )
    //    root = 0x69b0f3ede82627dee277a148a6b6253d16c15c2c086860561ced9e02f8fe6b09
    //    tree.getProof(
    //        ["0x1111111111111111111111111111111111111111", "5500000000000000000"]
    //    ) = [
    //      '0x17f48f2d4fb34ee5087ddc31713d906209936482a309dc52d9b790c15118fb86',
    //      '0xfe03c59aa489ab0876103ee0259c853e3358129295e6d86c356ce77fad8e580f'
    //    ]
    //    tree.getProof(
    //        ['0x2222222222222222222222222222222222222222', '10000000000000000000']
    //    ) = [
    //      '0x998d3e95033f5e4508cedcb79e9070e4301df6d2d0e17d55737129f2d6bf4cc3',
    //      '0xfe03c59aa489ab0876103ee0259c853e3358129295e6d86c356ce77fad8e580f'
    //    ]
    //    tree.getProof(
    //            ['0x3333333333333333333333333333333333333333', '93200000000000000000']
    //    ) = [
    //      '0x395b4e4ef555855f570f7e63fe0711a45eb1c38a73bf20ad4d867d8c4f4b85da'
    //    ]
    bytes32 merkleRoot2 =
        bytes32(
            0x69b0f3ede82627dee277a148a6b6253d16c15c2c086860561ced9e02f8fe6b09
        );
    bytes32[] proof2User1 = [
        bytes32(
            0x17f48f2d4fb34ee5087ddc31713d906209936482a309dc52d9b790c15118fb86
        ),
        bytes32(
            0xfe03c59aa489ab0876103ee0259c853e3358129295e6d86c356ce77fad8e580f
        )
    ];
    bytes32[] proof2User2 = [
        bytes32(
            0x998d3e95033f5e4508cedcb79e9070e4301df6d2d0e17d55737129f2d6bf4cc3
        ),
        bytes32(
            0xfe03c59aa489ab0876103ee0259c853e3358129295e6d86c356ce77fad8e580f
        )
    ];
    bytes32[] proof2User3 = [
        bytes32(
            0x395b4e4ef555855f570f7e63fe0711a45eb1c38a73bf20ad4d867d8c4f4b85da
        )
    ];
    uint256 amount2User1 = 5500000000000000000;
    uint256 amount2User2 = 10000000000000000000;
    uint256 amount2User3 = 93200000000000000000;

    uint256 defaultMaxUsersToClaim = 3;

    struct DistributionData {
        bytes32 merkleRoot;
        bytes32[][3] proofs;
        uint256[3] amounts;
    }
    DistributionData[] distributions;

    function setUp() external {
        rebateToken = new ERC20("Arbitrum", "ARB");
        rebateHandler = new RebateHandler(
            address(rebateToken),
            owner,
            defaultMaxUsersToClaim,
            24 hours,
            3 days
        );
        deal({token: address(rebateToken), to: owner, give: 1000000 ether});
        distributions.push(
            DistributionData({
                merkleRoot: merkleRoot1,
                proofs: [proof1User1, proof1User2, proof1User3],
                amounts: [amount1User1, amount1User2, amount1User3]
            })
        );
        distributions.push(
            DistributionData({
                merkleRoot: merkleRoot2,
                proofs: [proof2User1, proof2User2, proof2User3],
                amounts: [amount2User1, amount2User2, amount2User3]
            })
        );
    }

    function testInitialVariables() external {
        assertEq(address(rebateHandler.rebateToken()), address(rebateToken));
        // check is claimedAddresses is empty.
        // It should revert if we try to access any of its index if its empty
        vm.expectRevert();
        rebateHandler.claimedAddresses(0);
        assertEq(rebateHandler.merkleRoot(), bytes32(0));
        assertEq(rebateHandler.lastUpdated(), 0);
        assertEq(rebateHandler.maxUsersToClaim(), defaultMaxUsersToClaim);
        assertEq(rebateHandler.timeElapsedForUpdate(), 24 hours);
        assertEq(rebateHandler.maxAmountToClaim(), 0);
        assertEq(rebateHandler.amountClaimed(), 0);
        assertEq(rebateHandler.owner(), owner);
    }

    function testVariablseAfterMerkleRootUpdate() external {
        vm.startPrank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        DistributionData memory distributionData = distributions[0];
        uint256 maxAmountToClaim = distributionData.amounts[0] +
            distributionData.amounts[1] +
            distributionData.amounts[2];
        vm.expectEmit(true, true, true, true, address(rebateHandler));
        emit MerkleRootUpdated(
            distributionData.merkleRoot,
            maxAmountToClaim
        );
        rebateHandler.updateMerkleRoot(
            distributionData.merkleRoot,
            maxAmountToClaim
        );
        vm.stopPrank();
        // check is claimedAddresses is empty.
        // It should revert if we try to access any of its index if its empty
        vm.expectRevert();
        rebateHandler.claimedAddresses(0);
        assertEq(rebateHandler.merkleRoot(), distributionData.merkleRoot);
        assertEq(rebateHandler.lastUpdated(), block.timestamp);
        assertEq(rebateHandler.maxAmountToClaim(), maxAmountToClaim);
        assertEq(rebateHandler.amountClaimed(), 0);
    }

    function testVariablesAfterMultipleUpdates() external {
        vm.startPrank(owner);
        rebateToken.transfer(address(rebateHandler), 4000 ether);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        uint256 newTimestamp = block.timestamp + 24 hours;
        vm.warp(newTimestamp);
        uint256 maxAmountToClaim = distributions[1].amounts[0] +
            distributions[1].amounts[1] +
            distributions[1].amounts[2];
        rebateHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            maxAmountToClaim
        );
        vm.stopPrank();

        // check is claimedAddresses is empty.
        // It should revert if we try to access any of its index if its empty
        vm.expectRevert();
        rebateHandler.claimedAddresses(0);
        assertEq(rebateHandler.merkleRoot(), distributions[1].merkleRoot);
        assertEq(rebateHandler.lastUpdated(), newTimestamp);
        assertEq(rebateHandler.maxAmountToClaim(), maxAmountToClaim);
        assertEq(rebateHandler.amountClaimed(), 0);
    }

    function testRevertWhenBalanceisLow() external {
        uint256 balanceNeeded = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.startPrank(owner);
        rebateToken.transfer(address(rebateHandler), balanceNeeded - 1);
        vm.expectRevert("Balance less than maxAmountToClaim");
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        vm.stopPrank();
    }

    function testRevertWhenUpdateTimeNotElapsed() external {
        vm.startPrank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        vm.expectRevert("Cannot update before 24 hours");
        rebateHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            distributions[1].amounts[0] +
                distributions[1].amounts[1] +
                distributions[1].amounts[2]
        );
        vm.stopPrank();
    }

    function testRevertWhenUpdaterNotAdmin() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        vm.expectRevert("Ownable: caller is not the owner");
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
    }

    function _checkDistributionWorks(
        DistributionData memory distributionData
    ) internal {
        vm.prank(owner);
        rebateHandler.updateMerkleRoot(
            distributionData.merkleRoot,
            distributionData.amounts[0] +
                distributionData.amounts[1] +
                distributionData.amounts[2]
        );
        uint256 totalClaimed = 0;
        uint256 initialRebateHandlerBalance = rebateToken.balanceOf(
            address(rebateHandler)
        );

        for (uint256 i = 0; i < defaultMaxUsersToClaim; i++) {
            address user = users[i];
            uint256 initialUserBalance = rebateToken.balanceOf(user);
            vm.prank(user);
            vm.expectEmit(true, true, true, true, address(rebateHandler));
            emit RewardPaid(
                user, distributionData.amounts[i]
            );
            rebateHandler.claimReward(
                distributionData.proofs[i],
                distributionData.amounts[i]
            );
            assertEq(
                rebateToken.balanceOf(user),
                distributionData.amounts[i] + initialUserBalance
            );
            assertTrue(rebateToken.balanceOf(user) > initialUserBalance);
            totalClaimed += distributionData.amounts[i];
        }
        assertEq(
            rebateToken.balanceOf(address(rebateHandler)),
            initialRebateHandlerBalance - totalClaimed
        );
    }

    function testClaimSingleDistribution() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        _checkDistributionWorks(distributions[0]);
    }

    function testClaimMultipleDistributions() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 4000 ether);
        _checkDistributionWorks(distributions[0]);
        vm.warp(block.timestamp + 24 hours);
        _checkDistributionWorks(distributions[1]);
    }

    function testVariablesAfterClaimSingleDistribution() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        _checkDistributionWorks(distributions[0]);
        assertEq(rebateHandler.claimedAddresses(0), user1);
        assertEq(rebateHandler.claimedAddresses(1), user2);
        assertEq(rebateHandler.claimedAddresses(2), user3);
        assertEq(
            rebateHandler.amountClaimed(),
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
    }

    function testVariablesAfterUpdateClaimUpdate() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        _checkDistributionWorks(distributions[0]);
        uint256 newTimestamp = block.timestamp + 24 hours;
        vm.warp(newTimestamp);
        uint256 maxAmountToClaim = distributions[1].amounts[0] +
            distributions[1].amounts[1] +
            distributions[1].amounts[2];
        vm.prank(owner);
        rebateHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            maxAmountToClaim
        );

        // check is claimedAddresses is empty.
        // It should revert if we try to access any of its index if its empty
        vm.expectRevert();
        rebateHandler.claimedAddresses(0);
        assertEq(rebateHandler.merkleRoot(), distributions[1].merkleRoot);
        assertEq(rebateHandler.lastUpdated(), newTimestamp);
        assertEq(rebateHandler.maxAmountToClaim(), maxAmountToClaim);
        assertEq(rebateHandler.amountClaimed(), 0);
    }

    function testRevertWhileClaimingBeforeUpdate() external {
        vm.prank(user1);
        vm.expectRevert("Empty Merkle Root");
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testRevertWhenClaimMoreThanOnce() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(owner);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        vm.prank(user1);
        vm.expectRevert("Rebate already claimed");
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testReceivePartialAmountLeft() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        vm.prank(owner);
        uint256 maxAmountToClaim = distributions[0].amounts[0] + (distributions[0].amounts[1] / 2);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        assertEq(rebateToken.balanceOf(user1), distributions[0].amounts[0]);
        vm.prank(user2);
        rebateHandler.claimReward(
            distributions[0].proofs[1],
            distributions[0].amounts[1]
        );
        assertEq(rebateToken.balanceOf(user2), (distributions[0].amounts[1] / 2));
    }

    function testRevertInvalidProof() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(owner);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        vm.expectRevert("Invalid Proof");
        rebateHandler.claimReward(
            distributions[1].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testRevertInvalidAmount() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(owner);
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        vm.expectRevert("Invalid Proof");
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[1].amounts[0]
        );
    }

    function testRevertAfterAllRewardsClaimed() external {
        vm.prank(owner);
        rebateToken.transfer(address(rebateHandler), 1000 ether);
        vm.prank(owner);
        uint256 maxAmountToClaim = distributions[0].amounts[0] + distributions[0].amounts[1];
        rebateHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        rebateHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        vm.prank(user2);
        rebateHandler.claimReward(
            distributions[0].proofs[1],
            distributions[0].amounts[1]
        );
        vm.prank(user3);
        vm.expectRevert("All rebates have been Claimed");
        rebateHandler.claimReward(
            distributions[0].proofs[2],
            distributions[0].amounts[2]
        );
    }
}
