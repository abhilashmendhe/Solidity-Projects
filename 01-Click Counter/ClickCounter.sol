// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version


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