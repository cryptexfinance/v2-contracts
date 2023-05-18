// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRebateHandler {
    /// @notice Emitted when the merkle root is updated
    event MerkleRootUpdated(bytes32 merkleRoot, uint256 maxAmountToClaim);
    /// @notice Emitted when reward is paid to a user
    event RewardPaid(address indexed user, uint256 reward);

    function updateMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _maxAmountToClaim
    ) external;

    function claimReward(bytes32[] memory proof, uint256 amount) external;

    function reclaimUnusedReward(address account) external;
}
