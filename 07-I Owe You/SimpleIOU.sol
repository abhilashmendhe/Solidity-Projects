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

    mapping (address => mapping (address=>uint256)) public debts;


    modifier onlyOwner() {
        require(i_owner==msg.sender, "Only owner can perform the operations.");
        _;
    }


    constructor() {
        i_owner = msg.sender;
        Friend memory mySelf = Friend(msg.sender, 0, true);
        friendGroup.push(mySelf);
        friendsInfo[msg.sender] = mySelf;
    }

    function getAllFriends() public view returns (Friend[] memory) {
        return friendGroup;
    }
    function addFriend(address _friendAddr) public onlyOwner {
        require(_friendAddr != address(0), "Friend's address is invalid.");
        require(!friendsInfo[_friendAddr].inGroup, "Friend is already in the group.");
        Friend memory friend = Friend(_friendAddr, 0, true);
        friendGroup.push(friend);
        friendsInfo[_friendAddr] = friend;
    }

    function addDebtor(address _debtor, uint256 amt) public {
        require(_debtor != address(0), "Friend's address is invalid.");
        require(!friendsInfo[_debtor].inGroup, "Friend is already in the group.");
        require(amt > 0, "Amount should be greater than 0");
        debts[msg.sender][_debtor] += amt;
    }

    function resetDebt(address _debtor) public {
        require(_debtor != address(0), "Friend's address is invalid.");
        require(!friendsInfo[_debtor].inGroup, "Friend is already in the group.");
        debts[msg.sender][_debtor] = 0;
    }

    function checkYourInfo() public view returns (Friend memory) {
        require(!friendsInfo[msg.sender].inGroup, "You are not registered.");
        return friendsInfo[msg.sender];
    }
}