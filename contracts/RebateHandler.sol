// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IRebateHandler.sol";

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
        require(
            _timeToReclaimRewards > _timeElapsedForUpdate,
            "_timeToReclaimRewards less than timeElapsedForUpdate"
        );
        rebateToken = IERC20(rebateTokenAddress);
        maxUsersToClaim = _maxUsersToClaim;
        timeElapsedForUpdate = _timeElapsedForUpdate;
        timeToReclaimRewards = _timeToReclaimRewards;
        transferOwnership(owner);
    }

    /// @inheritdoc IRebateHandler
    function updateMerkleRoot(
        bytes32 _merkleRoot,
        uint256 _maxAmountToClaim
    ) external onlyOwner {
        require(
            (block.timestamp - lastUpdated >= timeElapsedForUpdate) ||
                (lastUpdated == uint256(0)),
            "Cannot update before timeElapsedForUpdate"
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

    /// @inheritdoc IRebateHandler
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

    /// @inheritdoc IRebateHandler
    function reclaimUnusedReward(address account) external onlyOwner {
        require(
            (block.timestamp - lastUpdated >= timeToReclaimRewards),
            "time less than timeToReclaimRewards"
        );
        rebateToken.safeTransfer(account, rebateToken.balanceOf(address(this)));
    }

    function updateMaxUsersToClaim(
        uint256 _maxUsersToClaim
    ) external onlyOwner {
        require(_maxUsersToClaim != 0, "_maxUsersToClaim can't be 0");
        maxUsersToClaim = _maxUsersToClaim;
    }

    function updateTimeElapsedForUpdate(
        uint256 _timeElapsedForUpdate
    ) external onlyOwner {
        require(_timeElapsedForUpdate != 0, "_maxUsersToClaim can't be 0");
        timeElapsedForUpdate = _timeElapsedForUpdate;
    }

    function updateTimeToReclaimRewards(
        uint256 _timeToReclaimRewards
    ) external onlyOwner {
        require(_timeToReclaimRewards != 0, "_maxUsersToClaim can't be 0");
        require(
            _timeToReclaimRewards > timeElapsedForUpdate,
            "value less than timeElapsedForUpdate"
        );
        timeToReclaimRewards = _timeToReclaimRewards;
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
