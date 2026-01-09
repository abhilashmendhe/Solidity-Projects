// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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