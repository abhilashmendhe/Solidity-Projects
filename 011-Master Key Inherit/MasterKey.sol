// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a secure Vault contract that only the owner (master key holder) can control. 
    You'll split your logic into two parts: a reusable 'Ownable' base contract and a 'VaultMaster' contract that inherits from it. 
    Only the owner can withdraw funds or transfer ownership. This shows how to use Solidity's inheritance model to write clean, reusable 
    access control patterns — just like in real-world production contracts. It's like building a secure digital safe where only the master
    key holder can access or delegate control.
*/

import "./Ownable.sol";

contract VaultMaster is Ownable {

    error VaultMaster__NotEnoughETHDeposit(string);
    error VaultMaster__WithdrawFailed(string);

    event DepositETHSuccess(address indexed account, uint256 value);
    event WithdrawETHSuccess(address indexed account, uint256 value);

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    function getOwnerBalance() public view returns (uint256) {
        address currentOwner = ownerAddress();
        return currentOwner.balance;
    }
    function deposit() public payable {
        if (msg.value <= 0) {
            revert VaultMaster__NotEnoughETHDeposit("ETH should not be zero.");
        }
        address currentOwner = ownerAddress();
        require(currentOwner != msg.sender, "Owner cannot deposit. Owner can only withdraw!");
    }

    function withdraw(uint256 _amount) public {
        require(_amount <= getBalance(), "Insufficient balance");
        
        address currentOwner = ownerAddress();
        (bool success, ) = payable(currentOwner).call{value: _amount}("");
        // require(condition);
        if(!success) {
            revert VaultMaster__WithdrawFailed("Transfer Failed");
        }
        emit WithdrawETHSuccess(currentOwner, _amount);
    }
}