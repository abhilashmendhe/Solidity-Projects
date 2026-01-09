// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
    Build a simple IOU contract for a private group of friends. Each user can deposit ETH, 
    track personal balances, log who owes who, and settle debts — all on-chain. 
    You’ll learn how to accept real Ether using `payable`, transfer funds between addresses, 
    and use nested mappings to represent relationships like 'Alice owes Bob'. 
    This contract mirrors real-world borrowing and lending, and teaches you how to model those 
    interactions in Solidity.
*/

contract SimpleIOU {

    address public immutable i_owner;

    struct Friend {
        address friendAddr;
        uint256 balance;
        bool inGroup;
    }
    Friend[] public friendGroup;
    mapping (address => Friend) public friendsInfo; 

    mapping (address => mapping (address=>Friend)) public debts;


    modifier onlyOwner() {
        require(i_owner==msg.sender, "Only owner can perform operations.");
        _;
    }


    constructor() {
        i_owner = msg.sender;
        Friend memory mySelf = Friend(msg.sender, 0, true);
        friendGroup.push(mySelf);
        friendsInfo[msg.sender] = mySelf;
    }





}