// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a secure digital vault where users can deposit and withdraw tokenized gold (or any valuable asset), ensuring it's protected from 
    reentrancy attacks. Imagine you're creating a decentralized version of Fort Knox — users lock up tokenized gold, and can later withdraw it. 
    But just like a real vault, this contract must prevent attackers from repeatedly triggering the withdrawal logic before the balance updates. 
    You'll implement the `nonReentrant` modifier to block reentry attempts, and follow Solidity security best practices to lock down your 
    contract. This project shows how a seemingly simple withdrawal function can become a vulnerability — and how to defend it properly.
*/

contract GoldVault {

    error GoldVault__EntranceRestricted();
    error GoldVault__DepositValueZero(string);

    enum Status {
        ENTERED,
        NOT_ENTERED
    }
    Status private _status;
    
    mapping (address => uint256) public goldBalance;

    constructor() {
        _status = Status.NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == Status.ENTERED) {
            revert GoldVault__EntranceRestricted();
        }
        _status = Status.ENTERED;
        _;
        _status = Status.NOT_ENTERED;
    }

    function deposit() external payable {
        if (msg.value == 0) {
            revert GoldVault__DepositValueZero("Deposit value should be more than zero.");
        }
        goldBalance[msg.sender] += msg.value;
    }

    function unsafeWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH Transfer Failed");
        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        goldBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH Transfer Failed");
    }
}