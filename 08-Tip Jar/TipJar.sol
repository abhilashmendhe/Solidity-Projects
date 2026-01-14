// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
    Build a multi-currency digital tip jar! Users can send Ether directly or simulate tips in foreign currencies like USD or EUR. 
    You'll learn how to manage currency conversion, handle Ether payments using `payable` and `msg.value`, and keep track of individual contributions. 
    Think of it like an advanced version of a 'Buy Me a Coffee' button — but smarter, more global, and Solidity-powered.
*/

error NotOwner();

contract TipJar {

    address private immutable iOwner;

    struct Tipper {
        address tipperAddr;
        uint256 donationAmt;
    }

    Tipper[] private tippers;
    // mapping (address => uint256) private tippersDonationAmt;

    constructor() {
        iOwner = msg.sender;
    }
    function _onlyOwner() internal view {
        if (msg.sender != iOwner) revert NotOwner();
        
    }
    modifier onlyOnwer() {
        _onlyOwner();
        _;
    }
    function getOwner() public view onlyOnwer returns(address) {
        return iOwner;
    }

    function viewTippers() public view onlyOnwer returns(Tipper[] memory) {
        return tippers;
    }
    
    function tip() public payable {
        require(msg.sender != iOwner, "Onwer can't fund itself.");
        require(msg.value >= 300000000000000, "Minimum gas value should be 300000000000000 wei");
        tippers.push(Tipper(msg.sender, msg.value));
    }
    
    function withdraw() public onlyOnwer payable {
        require(tippers.length > 0, "No tips are there to withdraw.");
        delete tippers;
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Withdraw Failed.");
    }
}