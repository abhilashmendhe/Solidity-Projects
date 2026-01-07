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

    mapping (address => string[]) public withdrawlTreasures;

    function addTreasure(string memory tName) public {
        treasures.push(tName);
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

    function listUsersOfTreasure(uint256 tIndex) public view checkIndex(tIndex) returns (User[] memory) {
        return treas_users[treasures[tIndex]];
    }

    function allowWithdraw(uint256 tIndex, address user) public checkIndex(tIndex) {
        require(i_owner==msg.sender, "Only owner of the treasure can approve for withdrawal.");
        User[] storage users = treas_users[treasures[tIndex]];

        require(users.length>0, "No users found to approve for withdrawal.");
        for(uint256 i = 0; i < users.length; i++) {
            if(users[i].user==user) {
                users[i].approval = true;
            }
        }
    }

    function viewWithdrawlTreasure() public view returns (string[] memory) {
        return withdrawlTreasures[msg.sender];
    }    
    
    function withdrawTreasure(uint256 tIndex) public {
        
        User[] memory users = treas_users[treasures[tIndex]];
        
        for(uint256 i=0; i<users.length; i++) {
            if (users[i].approval) {
                withdrawlTreasures[msg.sender].push(treasures[tIndex]);
            }
        }
    }
}