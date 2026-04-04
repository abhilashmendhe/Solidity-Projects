// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {IRebaseToken} from "./IRebaseToken.sol";

contract Vault {
    error Vault__RedeemFailed();

    IRebaseToken private immutable I_REBASE_TOKEN;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    // We need to pass the token address to the constructor
    constructor(IRebaseToken _rebaseToken) {
        I_REBASE_TOKEN = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Create a deposit function that mints tokens to the user equal to the amount of ETH the user has sent
     */
    function deposit() external payable {
        // 1. We need to use the ETH amount the user has sent to mint the tokens
        I_REBASE_TOKEN.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Create a redeem function that burns tokens from the user and sends the user ETH
     * @param _amount The amount rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        // 1. Burn the tokens from the user
        I_REBASE_TOKEN.burn(msg.sender, _amount);

        // 2. We need to send the user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }

        emit Redeem(msg.sender, _amount);
    }

    // Create a way to add rewards to the vault

    /**
     * @return Returns the Rebase token address
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(I_REBASE_TOKEN);
    }
}
