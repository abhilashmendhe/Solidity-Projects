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

    modifier onlyBankManager() {
        require(msg.sender==bm.bankManagerAddress, "Only bank manager can perform operations.");
        _;
    }

    modifier onlyNormalMemeber() {
        require(msg.sender!=bm.bankManagerAddress, "Only account holders can perform operations");
        _;
    }

    struct User {
        address userAddress;
        uint256 amt;
        bool registered;
    }
    User[] users;
    mapping (address => User) public registered_users;


    constructor(string memory name) {
        bm = BankManager(name, msg.sender, 0);
    }

    function createAccount() public payable onlyNormalMemeber {

        require(registered_users[msg.sender].userAddress==0x0000000000000000000000000000000000000000, "Account already exists.");
        require(msg.value>=50000000000000, "Minimum wei atleast 50000000000000");
        uint256 bankFee = 5000000000000;
        User memory user = User(msg.sender, msg.value-bankFee, false);
        registered_users[msg.sender] = user;
        users.push(user);
        bm.balance += bankFee;
    }
    function getMember(address _user) public view onlyBankManager returns(User memory) {
        return registered_users[_user];
    }
    function getAllMembers() public view onlyBankManager returns (User[] memory) {
        return users;
    }
    function approveAccount(address user) public onlyBankManager {
        registered_users[user].registered = true;
    }
    function deposit() public payable onlyNormalMemeber {
        require(registered_users[msg.sender].userAddress!=0x0000000000000000000000000000000000000000, "Account does not exists.");
        uint256 bankFee = 1000000000000;
        registered_users[msg.sender].amt += (msg.value-bankFee);
        bm.balance += bankFee;
    }

    function withdraw() public payable onlyNormalMemeber {
        require(registered_users[msg.sender].userAddress!=0x0000000000000000000000000000000000000000, "Account does not exists.");
        registered_users[msg.sender].amt -= msg.value;
    }
}

