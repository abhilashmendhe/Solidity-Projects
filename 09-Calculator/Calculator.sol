// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a contract that uses another contract to do calculations. 
    You'll learn how contracts can talk to each other by calling functions of other contracts 
    (using `address casting`). It's like having one app ask another app to do some math,
    showing how to interact with other contracts.
*/

import "./AdvanceCalculator.sol";

contract Calculator {

    
    address immutable _iowner;
    AdvanceCalculator advCalc = new AdvanceCalculator();

    constructor() {
        _iowner = msg.sender;
    }

    modifier OnlyOwner {
        require(_iowner == msg.sender, "Only owner can perform math operations.");
        _;
    }
    
    function add(int256 x, int256 y) public view OnlyOwner returns (int256) {
        return x + y;
    }

    function subtract(int256 x, int256 y) public view OnlyOwner returns (int256) {
        return x - y;
    }

    function multiply(uint256 x, uint256 y) public view OnlyOwner returns (uint256) {
        return x * y;
    }

    function divide(uint256 x, uint256 y) public view OnlyOwner returns (uint256) {
        return x / y;
    }

    function modulus(uint256 x, uint256 y) public view OnlyOwner returns (uint256) {
        return x % y;
    }

}