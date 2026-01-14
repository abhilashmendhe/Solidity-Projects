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
    // Friend[] public friendGroup;
    // mapping (address => Friend) public friendsInfo;
    mapping (address => Friend[]) public friendsInfo; 

    
    mapping (address => mapping (address=>uint256)) public debts;
    mapping (address => address[]) public debtsList;
    

    modifier onlyOwner() {
        require(i_owner==msg.sender, "Only owner can perform the operations.");
        _;
    }


    constructor() {
        i_owner = msg.sender;
        Friend memory mySelf = Friend(msg.sender, msg.sender.balance, true);
        friendGroup.push(mySelf);
        friendsInfo[msg.sender] = mySelf;
    }

    function getAllFriends() public view returns (Friend[] memory) {
        return friendGroup;
    }
    function addFriend(address _friendAddr) public onlyOwner {
        require(_friendAddr != address(0), "Friend's address is invalid.");
        require(!friendsInfo[_friendAddr].inGroup, "Friend is already in the group.");
        Friend memory friend = Friend(_friendAddr, _friendAddr.balance, true);
        friendGroup.push(friend);
        friendsInfo[_friendAddr] = friend;
    }

    // Creditor performs this operation.
    function addDebtor(address _debtor, uint256 amt) public {
        require(_debtor != address(0), "Friend's address is invalid.");
        require(_debtor != msg.sender, "You can't add your own debt.");
        require(friendsInfo[_debtor].inGroup, "Friend is not in the group");
        require(amt > 0, "Amount should be greater than 0");
        debts[_debtor][msg.sender] += amt;
        debtsList[_debtor].push(msg.sender);
    }

    // Creditor performs this operation.
    function resetDebt(address _debtor) public {
        require(_debtor != address(0), "Friend's address is invalid.");
        require(friendsInfo[_debtor].inGroup, "Friend is not in the group");
        debts[_debtor][msg.sender] = 0;
        address[] storage creditorList = debtsList[_debtor];
        
        uint256 index;
        for(uint256 i = 0; i < creditorList.length; i++) {
            if (creditorList[i] == msg.sender) {
                index = i;
                break;
            }
        }
        delete creditorList[index];
    }
    // Debtor performs this to view all creditor's debt
    function getCreditorList() public view returns(address[] memory) {
        require(friendsInfo[msg.sender].inGroup, "Friend is not in the group");
        address[] memory creditorList = debtsList[msg.sender];
        return creditorList;
    }
    function checkYourInfo() public view returns (Friend memory) {
        require(friendsInfo[msg.sender].inGroup, "You are not registered.");
        return friendsInfo[msg.sender];
    }
    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function payDebtWithNoRealETH(address _creditTo) public payable {
        require(friendsInfo[msg.sender].inGroup, "You are not registered.");
        require(friendsInfo[_creditTo].inGroup, "Your friend is not registered in the group.");
        require(msg.value <= friendsInfo[msg.sender].balance, "You don't have enough eth to pay your debt.");
        require(msg.value <= debts[msg.sender][_creditTo], "You are paying high amount of debt.");
        
        friendsInfo[msg.sender].balance -= msg.value;
        friendsInfo[_creditTo].balance += msg.value;
        debts[msg.sender][_creditTo] -= msg.value;
    }
}