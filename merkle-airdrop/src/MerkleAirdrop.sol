// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    // Some list of addresses
    // Allow someone in the list to claim tokens
    address[] claimers;
    bytes32 private immutable I_MERKLEROOT;
    IERC20 private immutable I_AIRDROPTOKEN;
    mapping(address claimer => bool claimed) private sHasClaimed;

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLEROOT = merkleRoot;
        I_AIRDROPTOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // Check if they have claimed
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Calculate using the account and the amount, the hash -> leaf node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, I_MERKLEROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        sHasClaimed[account] = true;
        emit Claim(account, amount);
        I_AIRDROPTOKEN.safeTransfer(account, amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLEROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_AIRDROPTOKEN;
    }
}
