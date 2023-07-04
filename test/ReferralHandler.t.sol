// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../contracts/ReferralHandler.sol";

contract ReferralHandlerTest is Test {
    ERC20 rewardToken;
    ReferralHandler referralHandler;

    event MerkleRootUpdated(bytes32 merkleRoot, uint256 maxAmountToClaim);
    event RewardPaid(address indexed user, uint256 reward);

    address owner = address(0x51);
    address merkleRootAdmin = address(0x52);
    address user1 = address(0x1111111111111111111111111111111111111111);
    address user2 = address(0x2222222222222222222222222222222222222222);
    address user3 = address(0x3333333333333333333333333333333333333333);
    address[3] users = [user1, user2, user3];
    uint256 defaultMaxUsersToClaim = 3;
    uint256 timeElapsedForUpdate = 7 days;
    uint256 timeToReclaimRewards = 30 days;

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

    struct DistributionData {
        bytes32 merkleRoot;
        bytes32[][3] proofs;
        uint256[3] amounts;
    }
    DistributionData[] distributions;

    function setUp() external {
        rewardToken = new ERC20("Arbitrum", "ARB");
        referralHandler = new ReferralHandler(
            address(rewardToken),
            owner,
            merkleRootAdmin,
            timeElapsedForUpdate,
            timeToReclaimRewards
        );
        deal({token: address(rewardToken), to: owner, give: 1000000 ether});
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
        assertEq(address(referralHandler.rewardToken()), address(rewardToken));
        // check is claimedAddresses is empty.
        assertEq(referralHandler.merkleRoot(), bytes32(0));
        assertEq(referralHandler.lastUpdated(), 0);
        assertEq(referralHandler.timeElapsedForUpdate(), timeElapsedForUpdate);
        assertEq(referralHandler.timeToReclaimRewards(), timeToReclaimRewards);
        assertEq(referralHandler.maxAmountToClaim(), 0);
        assertEq(referralHandler.amountClaimed(), 0);
        assertEq(referralHandler.merkleRootAdmin(), merkleRootAdmin);
        assertEq(referralHandler.owner(), owner);
        assertEq(referralHandler.addressExists(1, user1), false);
        assertEq(referralHandler.addressExists(1, user2), false);
        assertEq(referralHandler.addressExists(1, user3), false);
    }

    function testVariablseAfterMerkleRootUpdate() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        DistributionData memory distributionData = distributions[0];
        uint256 maxAmountToClaim = distributionData.amounts[0] +
            distributionData.amounts[1] +
            distributionData.amounts[2];
        vm.expectEmit(true, true, true, true, address(referralHandler));
        emit MerkleRootUpdated(distributionData.merkleRoot, maxAmountToClaim);
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributionData.merkleRoot,
            maxAmountToClaim
        );
        // check is addressExists is empty.
        assertEq(referralHandler.addressExists(2, user1), false);
        assertEq(referralHandler.addressExists(2, user2), false);
        assertEq(referralHandler.addressExists(2, user3), false);
        assertEq(referralHandler.merkleRoot(), distributionData.merkleRoot);
        assertEq(referralHandler.lastUpdated(), block.timestamp);
        assertEq(referralHandler.amountClaimed(), 0);
    }

    function testVariablesAfterMultipleUpdates() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 4000 ether);
        vm.startPrank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        uint256 newTimestamp = block.timestamp + timeElapsedForUpdate;
        vm.warp(newTimestamp);
        uint256 maxAmountToClaim = distributions[1].amounts[0] +
            distributions[1].amounts[1] +
            distributions[1].amounts[2];
        referralHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            maxAmountToClaim
        );
        vm.stopPrank();

        // check is addressExists is empty.
        assertEq(referralHandler.addressExists(2, user1), false);
        assertEq(referralHandler.addressExists(2, user2), false);
        assertEq(referralHandler.addressExists(2, user3), false);
        assertEq(referralHandler.merkleRoot(), distributions[1].merkleRoot);
        assertEq(referralHandler.lastUpdated(), newTimestamp);
        assertEq(referralHandler.maxAmountToClaim(), maxAmountToClaim);
        assertEq(referralHandler.amountClaimed(), 0);
    }

    function testRevertWhenBalanceisLow() external {
        uint256 balanceNeeded = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), balanceNeeded - 1);
        vm.expectRevert("Balance less than maxAmountToClaim");
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
    }

    function testRevertWhenUpdateTimeNotElapsed() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        vm.startPrank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        vm.expectRevert("Cannot update before timeElapsedForUpdate");
        referralHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            distributions[1].amounts[0] +
                distributions[1].amounts[1] +
                distributions[1].amounts[2]
        );
        vm.stopPrank();
    }

    function testRevertWhenUpdaterNotAdmin() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        vm.expectRevert("caller can't update merkle root");
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
    }

    function _checkDistributionWorks(
        DistributionData memory distributionData,
        uint256 nonce
    ) internal {
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributionData.merkleRoot,
            distributionData.amounts[0] +
                distributionData.amounts[1] +
                distributionData.amounts[2]
        );
        uint256 totalClaimed = 0;
        uint256 initialreferralHandlerBalance = rewardToken.balanceOf(
            address(referralHandler)
        );

        for (uint256 i = 0; i < defaultMaxUsersToClaim; i++) {
            address user = users[i];
            uint256 initialUserBalance = rewardToken.balanceOf(user);
            assertFalse(referralHandler.addressExists(nonce, user));
            vm.prank(user);
            vm.expectEmit(true, true, true, true, address(referralHandler));
            emit RewardPaid(user, distributionData.amounts[i]);
            referralHandler.claimReward(
                distributionData.proofs[i],
                distributionData.amounts[i]
            );
            assertTrue(referralHandler.addressExists(nonce, user));
            assertEq(
                rewardToken.balanceOf(user),
                distributionData.amounts[i] + initialUserBalance
            );
            assertTrue(rewardToken.balanceOf(user) > initialUserBalance);
            totalClaimed += distributionData.amounts[i];
        }
        assertEq(
            rewardToken.balanceOf(address(referralHandler)),
            initialreferralHandlerBalance - totalClaimed
        );
    }

    function testClaimSingleDistribution() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        _checkDistributionWorks(distributions[0], 1);
    }

    function testClaimMultipleDistributions() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 4000 ether);
        _checkDistributionWorks(distributions[0], 1);
        vm.warp(block.timestamp + timeElapsedForUpdate);
        _checkDistributionWorks(distributions[1], 2);
    }

    function testVariablesAfterClaimSingleDistribution() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        _checkDistributionWorks(distributions[0], 1);
        assertEq(referralHandler.addressExists(1, user1), true);
        assertEq(referralHandler.addressExists(1, user2), true);
        assertEq(referralHandler.addressExists(1, user3), true);
        assertEq(
            referralHandler.amountClaimed(),
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
    }

    function testVariablesAfterUpdateClaimUpdate() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        _checkDistributionWorks(distributions[0], 1);
        uint256 newTimestamp = block.timestamp + timeElapsedForUpdate;
        vm.warp(newTimestamp);
        uint256 maxAmountToClaim = distributions[1].amounts[0] +
            distributions[1].amounts[1] +
            distributions[1].amounts[2];
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            maxAmountToClaim
        );

        assertEq(referralHandler.addressExists(1, user1), true);
        assertEq(referralHandler.addressExists(2, user1), false);
        assertEq(referralHandler.merkleRoot(), distributions[1].merkleRoot);
        assertEq(referralHandler.lastUpdated(), newTimestamp);
        assertEq(referralHandler.maxAmountToClaim(), maxAmountToClaim);
        assertEq(referralHandler.amountClaimed(), 0);
    }

    function testRevertWhileClaimingBeforeUpdate() external {
        vm.prank(user1);
        vm.expectRevert("Empty Merkle Root");
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testRevertWhenClaimMoreThanOnce() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        vm.prank(user1);
        vm.expectRevert("Rebate already claimed");
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testReceivePartialAmountLeft() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            (distributions[0].amounts[1] / 2);
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        assertEq(rewardToken.balanceOf(user1), distributions[0].amounts[0]);
        vm.prank(user2);
        referralHandler.claimReward(
            distributions[0].proofs[1],
            distributions[0].amounts[1]
        );
        assertEq(
            rewardToken.balanceOf(user2),
            (distributions[0].amounts[1] / 2)
        );
    }

    function testRevertInvalidProof() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        vm.expectRevert("Invalid Proof");
        referralHandler.claimReward(
            distributions[1].proofs[0],
            distributions[0].amounts[0]
        );
    }

    function testRevertInvalidAmount() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        vm.expectRevert("Invalid Proof");
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[1].amounts[0]
        );
    }

    function testRevertAfterAllRewardsClaimed() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        uint256 maxAmountToClaim = distributions[0].amounts[0] +
            distributions[0].amounts[1];
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            maxAmountToClaim
        );
        vm.prank(user1);
        referralHandler.claimReward(
            distributions[0].proofs[0],
            distributions[0].amounts[0]
        );
        vm.prank(user2);
        referralHandler.claimReward(
            distributions[0].proofs[1],
            distributions[0].amounts[1]
        );
        vm.prank(user3);
        vm.expectRevert("All rebates have been Claimed");
        referralHandler.claimReward(
            distributions[0].proofs[2],
            distributions[0].amounts[2]
        );
    }

    function testAdminReclaimUnusedAwards() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 4937 ether);
        _checkDistributionWorks(distributions[0], 1);
        uint256 amountClaimed = distributions[0].amounts[0] +
            distributions[0].amounts[1] +
            distributions[0].amounts[2];
        uint256 amountLeft = 4937 ether - amountClaimed;
        assertEq(rewardToken.balanceOf(address(referralHandler)), amountLeft);
        address reclaimAddress = address(0x53);
        assertEq(rewardToken.balanceOf(reclaimAddress), 0);
        vm.warp(block.timestamp + timeToReclaimRewards);
        vm.prank(owner);
        referralHandler.reclaimUnusedReward(reclaimAddress);
        assertEq(rewardToken.balanceOf(reclaimAddress), amountLeft);
        assertEq(rewardToken.balanceOf(address(referralHandler)), 0);
    }

    function testRevertNonAdminReclaimUnusedAwards() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 4937 ether);
        _checkDistributionWorks(distributions[0], 1);
        vm.warp(block.timestamp + timeToReclaimRewards);
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        referralHandler.reclaimUnusedReward(owner);
    }

    function testRevertReclaimUnusedAwardsTimeNotElapsed() external {
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 4937 ether);
        _checkDistributionWorks(distributions[0], 1);
        vm.prank(owner);
        vm.expectRevert("time less than timeToReclaimRewards");
        referralHandler.reclaimUnusedReward(owner);
    }

    function testUpdateTimeElapsedForUpdate() external {
        assertEq(referralHandler.timeElapsedForUpdate(), timeElapsedForUpdate);
        assertEq(referralHandler.lastUpdatedTimeElapsed(), block.timestamp);
        vm.warp(7 days + 1 hours);
        vm.prank(owner);
        referralHandler.updateTimeElapsedForUpdate(25 hours);
        assertEq(referralHandler.timeElapsedForUpdate(), 25 hours);
        assertEq(referralHandler.lastUpdatedTimeElapsed(), 7 days + 1 hours);
    }

    function testRevertNonAdminUpdateTimeElapsedForUpdate() external {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        referralHandler.updateTimeElapsedForUpdate(25 hours);
    }

    function testRevertUpdateTimeElapsedForUpdateWhenLessThanElapsed()
        external
    {
        vm.startPrank(owner);
        vm.expectRevert("Cannot update before timeElapsedForUpdate ends");
        referralHandler.updateTimeElapsedForUpdate(23 hours);
    }

    function testUpdateTimeElapsedForUpdateWorks() external {
        assertEq(referralHandler.timeElapsedForUpdate(), timeElapsedForUpdate);
        vm.startPrank(owner);
        vm.expectRevert("Cannot update before timeElapsedForUpdate ends");
        referralHandler.updateTimeElapsedForUpdate(25 hours);
        vm.warp(7 days + 1 hours);
        referralHandler.updateTimeElapsedForUpdate(25 hours);
        rewardToken.transfer(address(referralHandler), 1000 ether);
        vm.stopPrank();
        vm.startPrank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(
            distributions[0].merkleRoot,
            distributions[0].amounts[0] +
                distributions[0].amounts[1] +
                distributions[0].amounts[2]
        );
        vm.warp(block.timestamp + 24 hours);
        vm.expectRevert("Cannot update before timeElapsedForUpdate");
        referralHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            distributions[1].amounts[0] +
                distributions[1].amounts[1] +
                distributions[1].amounts[2]
        );
        vm.warp(block.timestamp + 1 hours);
        // next call should not not revert
        referralHandler.updateMerkleRoot(
            distributions[1].merkleRoot,
            distributions[1].amounts[0] +
                distributions[1].amounts[1] +
                distributions[1].amounts[2]
        );
        vm.stopPrank();
    }

    function testUpdateTimeToReclaimRewards() external {
        assertEq(referralHandler.timeToReclaimRewards(), timeToReclaimRewards);
        vm.prank(owner);
        referralHandler.updateTimeToReclaimRewards(10 days);
        assertEq(referralHandler.timeToReclaimRewards(), 10 days);
    }

    function testRevertUpdateTimeToReclaimRewardsWhenLessThanElapsed()
        external
    {
        vm.prank(owner);
        vm.expectRevert("value less than timeElapsedForUpdate");
        referralHandler.updateTimeToReclaimRewards(23 hours);
    }

    function testNonAdminUpdateTimeToReclaimRewards() external {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        referralHandler.updateTimeToReclaimRewards(23 hours);
    }

    function testChangeAdmin() external {
        address newAdmin = address(0x54);
        assertEq(referralHandler.owner(), owner);
        vm.prank(owner);
        referralHandler.transferOwnership(newAdmin);
        assertEq(referralHandler.owner(), newAdmin);
    }

    function testChangeMerkleRootAdmin() external {
        address newMerkleRootAdmin = address(0x55);
        assertEq(referralHandler.owner(), owner);
        vm.prank(owner);
        referralHandler.updateMerkleRootAdmin(newMerkleRootAdmin);
        assertEq(referralHandler.merkleRootAdmin(), newMerkleRootAdmin);
    }

    function testRevertNonAdminChangeMerkleRootAdmin() external {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        referralHandler.updateMerkleRootAdmin(user1);
    }

    function testRevertChangeMerkleRootAdminCantBeOwner() external {
        vm.prank(owner);
        vm.expectRevert("_merkleRootAdmin can't be same as Owner");
        referralHandler.updateMerkleRootAdmin(owner);
    }

    function testRevertChangeMerkleRootAdminCantBeZero() external {
        vm.prank(owner);
        vm.expectRevert("_merkleRootAdmin can't be zero");
        referralHandler.updateMerkleRootAdmin(address(0));
    }

    function testErrorMsgUpdateTimeElapsed() external {
        vm.expectRevert("_timeElapsedForUpdate can't be 0");
        vm.prank(owner);
        referralHandler.updateTimeElapsedForUpdate(0);
    }

    function testErrorMsgUpdateTimeToReclaimRewardsm() external {
        vm.expectRevert("_timeToReclaimRewards can't be 0");
        vm.prank(owner);
        referralHandler.updateTimeToReclaimRewards(0);
        uint256 _timeElapsedForUpdate = referralHandler.timeElapsedForUpdate();
        vm.expectRevert("value less than timeElapsedForUpdate");
        vm.prank(owner);
        referralHandler.updateTimeToReclaimRewards(_timeElapsedForUpdate);
    }

    function testDistributionWithDataFromApi() external {
        bytes32 _merkleRoot = bytes32(
            0x75d7c1117cb5689bf74e8bc2ec11d000908793bd33ef33c9387f7fc6f82ea1a1
        );
        vm.prank(owner);
        rewardToken.transfer(address(referralHandler), 10000 ether);
        vm.prank(merkleRootAdmin);
        referralHandler.updateMerkleRoot(_merkleRoot, 10000 ether);
        address _user1 = address(0x4379F61909Fe62D28CC4a12Ae3c2b9046D530d88);
        uint256 claimAmount = 8605440836294728661434;
        bytes32[] memory _proof = new bytes32[](7);
        _proof[0] = bytes32(
            0x48e94ec8506a454f3ee4ad08f31ffcc31d8364c9ace0fccda6d83594caef6efd
        );
        _proof[1] = bytes32(
            0xfa73bbec419cf23811bebb4d10c97f067e7ab6ea4dedba2735d6e4c84c6b4f66
        );
        _proof[2] = bytes32(
            0x67f5240ce7ef1f0db825967b2cd23efabea7cb2f7f956351f3064e7a0240ef4d
        );
        _proof[3] = bytes32(
            0x89ee6b50068a309f6f7187f8de878e5c9379c82ce074df994a60425cb2c867ed
        );
        _proof[4] = bytes32(
            0xce6c65ea2bb9f3b98c20ca219b11d605a59e88e4020a934347467650da5b881e
        );
        _proof[5] = bytes32(
            0xaf78c896fdb010bc6b099ba031f1198ee557980d6519b715322b4adf72a99906
        );
        _proof[6] = bytes32(
            0x0948dd3e6ec9facb3a83048d525547a6282a1a339e8cc08f4d9111e490f88a48
        );
        assertEq(rewardToken.balanceOf(_user1), 0);
        vm.prank(_user1);
        referralHandler.claimReward(_proof, claimAmount);
        assertEq(rewardToken.balanceOf(_user1), claimAmount);
    }
}
