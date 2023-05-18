// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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

    //    function claimReward(bytes32[] memory proof, address account, uint256 amount) external;
    function reclaimUnusedReward(address account) external;
}

contract RebateHandler is IRebateHandler, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) private addressExists;
    IERC20 public immutable rebateToken;
    address[] public claimedAddresses;
    bytes32 public merkleRoot;
    uint256 public lastUpdated;
    uint256 public maxUsersToClaim;
    uint256 public timeElapsedForUpdate;
    uint256 public maxAmountToClaim;
    uint256 public amountClaimed;
    uint256 public timeToReclaimRewards;

    constructor(
        address rebateTokenAddress,
        address owner,
        uint256 _maxUsersToClaim,
        uint256 _timeElapsedForUpdate,
        uint256 _timeToReclaimRewards
    ) {
        rebateToken = IERC20(rebateTokenAddress);
        maxUsersToClaim = _maxUsersToClaim;
        timeElapsedForUpdate = _timeElapsedForUpdate;
        timeToReclaimRewards = _timeToReclaimRewards;
        transferOwnership(owner);
    }

    function updateMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _maxAmountToClaim
    ) external onlyOwner {
        require(
            (block.timestamp - lastUpdated >= timeElapsedForUpdate) ||
                (lastUpdated == uint256(0)),
            "Cannot update before 24 hours"
        );
        require(
            rebateToken.balanceOf(address(this)) >= _maxAmountToClaim,
            "Balance less than maxAmountToClaim"
        );
        lastUpdated = block.timestamp;
        _resetAddressExists();
        delete claimedAddresses;
        amountClaimed = 0;
        maxAmountToClaim = _maxAmountToClaim;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot, _maxAmountToClaim);
    }

    function claimReward(bytes32[] memory proof, uint256 amount) external {
        require(merkleRoot != bytes32(0), "Empty Merkle Root");
        require(!addressExists[msg.sender], "Rebate already claimed");
        uint256 amountLeftToClaim = maxAmountToClaim - amountClaimed;
        require(amountLeftToClaim > 0, "All rebates have been Claimed");
        require(_verifyProof(proof, msg.sender, amount), "Invalid Proof");
        addressExists[msg.sender] = true;
        claimedAddresses.push(msg.sender);
        require(
            claimedAddresses.length <= maxUsersToClaim,
            "Exceeded Max number claims"
        );
        uint256 ClaimableAmount = amount < amountLeftToClaim
            ? amount
            : amountLeftToClaim;
        amountClaimed += ClaimableAmount;
        // Follows checks effects pattern. So there should be no re-entrancy exploit
        rebateToken.safeTransfer(msg.sender, ClaimableAmount);
        emit RewardPaid(msg.sender, ClaimableAmount);
    }

    function reclaimUnusedReward(
        address account
    ) external onlyOwner {
        require(
            (block.timestamp - lastUpdated >= timeToReclaimRewards),
            "less than 3 days since last update"
        );
        rebateToken.safeTransfer(account, rebateToken.balanceOf(address(this)));
    }

    function _resetAddressExists() internal {
        uint256 length = claimedAddresses.length;
        for (uint256 i = 0; i < length; i++) {
            delete addressExists[claimedAddresses[i]];
        }
    }

    function _verifyProof(
        bytes32[] memory proof,
        address account,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}

///1. Test when merkle root is empty (done)
///2. Test lastUpdated (done)
///3. updated maxUsersToClaim and check it can't be exceeded
///4. Can claim rewards (done)
///5. Can't claim more than once. (done)
///6. Can claim partial amount left after distributing (done)
///7. Test merkle root can be updated (done)
///8. Test that addressExist resets (done)
///9. Admin can reclaim amount left
///10. Can't update merkle root before 24 hours (done)
///11. Change admin
///12. end the program (not doing)
///13. Admin can claim left amount (duplicate 9)
///14. Raises error when there are no funds. (done)
/// 15. Change owner (duplicate 11)
/// 16. Test Re-entrancy for token sending
/// 17. Merkle root can onlu be updated by owner (done)
/// 18. Update owner (duplicate 9, 15)
/// 19. Updated other public variables (done)
/// 20. Another user can't steal/claim
/// 21. fails update when balance lower than maxAmountToClaim (done)
/// 22. non admin cannot reclaimUnusedReward
/// 23. Check overflow
/// 24. Incorrect proof and amount (done)
/// 25. test events (done)