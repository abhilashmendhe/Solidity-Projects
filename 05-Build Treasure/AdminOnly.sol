// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
    Build a contract that simulates a treasure chest controlled by an owner. 
    The owner can add treasure, approve withdrawals for specific users, and even withdraw treasure themselves. 
    Other users can attempt to withdraw, but only if the owner has given them an allowance and they haven't withdrawn before. 
    The owner can also reset withdrawal statuses and transfer ownership of the treasure chest. 
    This demonstrates how to create a contract with restricted access using a 'modifier' and `msg.sender`, similar to how only 
    an admin can perform certain actions in a game or application.
*/

contract TreasureContract {

    address public immutable i_owner;
    
    constructor() {
        i_owner = msg.sender;
    }

    string[] public treasures;

    struct User {
        address user;
        bool approval;
    }
    
    mapping(string => User[]) treas_users;

    function addTreasure(string memory tName) public {
        treasures.push(tName);
        // User[] memory users;
        // treas_users[tName] = users;
    }
    function listTreasures() public view returns(string[] memory) {
        return treasures;
    }
    
    modifier checkIndex(uint256 tIndex) {
        require(tIndex < treasures.length, "Index out of range");
        _;
    }

    function getTreasure(uint256 tIndex) public view checkIndex(tIndex) returns(string memory) {
        return treasures[tIndex];
    }

    function interestInTreasure(uint256 tIndex) public checkIndex(tIndex) {
        User[] storage users = treas_users[treasures[tIndex]];
        User memory newUser = User(msg.sender, false);
        users.push(newUser);
    }

}