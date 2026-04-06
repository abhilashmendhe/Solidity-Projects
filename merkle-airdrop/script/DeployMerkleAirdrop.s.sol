// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {CroissantToken} from "../src/CroissantToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private sMerkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private sAmountToTransfer = 4 * 25 * 1e18;

    function run() external returns (MerkleAirdrop, CroissantToken) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (MerkleAirdrop, CroissantToken) {
        vm.startBroadcast();
        CroissantToken croissantToken = new CroissantToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(sMerkleRoot, IERC20(address(croissantToken)));
        croissantToken.mint(croissantToken.owner(), sAmountToTransfer);
        croissantToken.transfer(address(merkleAirdrop), sAmountToTransfer);
        vm.stopBroadcast();
        return (merkleAirdrop, croissantToken);
    }
}
