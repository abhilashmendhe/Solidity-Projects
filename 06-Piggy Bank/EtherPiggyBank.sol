// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
    Let's make a digital piggy bank! Users can deposit and withdraw Ether (the cryptocurrency). 
    You'll learn how to manage balances (using `address` to identify users) and track who sent Ether (using `msg.sender`). 
    It's like a simple bank account on the blockchain, demonstrating how to handle Ether and user addresses.
*/

contract DigitalPiggyBank {
 
    struct BankManager {
        string name;
        address bankManagerAddress;
        uint256 balance;
    }

    BankManager bm;

    address[] users;
    mapping (address => bool) public registered_users;
    mapping (address => uint256) users_balances;


    constructor(string memory name) {
        bm = BankManager(name, msg.sender, 0);
    }

    
}
