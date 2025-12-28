// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version

/*
    Tasks
    -----
    Let's build a simple counter! Imagine a digital clicker. You'll create a 'function' named `click()`. 
    Each time someone calls this function, a number stored in the contract (a 'variable') will increase by one. 
    You'll learn how to declare a variable to hold a number (an `uint`) and create functions to change it (increment/decrement). 
    This is the very first step in making interactive smart contracts, showing how to store and modify data.
*/

contract ClickCounter {

    uint public variable = 0;

    function increment() public {
        variable++;
    }

    function decrement() public {
        variable--;
    }

    function getVariable() public view returns(uint) {
        return variable;
    }
}