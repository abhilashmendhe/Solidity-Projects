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
    address public advanceCalculatorAddress;

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

     
    function setAdvanceCalculator(address _address) public OnlyOwner {
        advanceCalculatorAddress = _address;
    }

    function pow(uint256 a, uint256 b) public view OnlyOwner returns(uint256) {
        // This process is called address casting — you’re converting an address into a contract reference so you can interact with it directly.
        AdvanceCalculator advCalc = AdvanceCalculator(advanceCalculatorAddress);
        return advCalc.pow(a, b);
    }

    function sqrt(uint256 a) public OnlyOwner returns (uint256) {
        // ABI stands for Application Binary Interface. 
        // Think of it as a contract’s "communication protocol" — it defines how data must be structured when one contract calls another.
        // We now call external contract when knowing only it's address.

        bytes memory data = abi.encodeWithSignature("sqrt(uint256 a)", a);
        (bool success, bytes memory returnData) = advanceCalculatorAddress.call(data);
        require(success, "External call failed");

        return abi.decode(returnData, (uint256));
    }
}