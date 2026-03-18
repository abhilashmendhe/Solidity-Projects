// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;


contract MyFirstToken {

    string private iName = "MyFirstTokenERC-20";
    string private iSymbol = "MFTE";
    uint8 private iDecimals = 18;
    uint256 private iTotalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {

    }

    function name() public view returns (string memory) {
        return iName;
    }
    
    function symbol() public view returns (string memory) {
        return iSymbol;
    }

    function decimals() public view returns (uint8) {
        return iDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return iTotalSupply;
    }


}