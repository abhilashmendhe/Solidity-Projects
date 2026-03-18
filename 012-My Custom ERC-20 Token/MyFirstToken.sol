// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Let's make your own digital currency! You'll create a basic token that can be transferred between users, 
    implementing the ERC20 standard. It's like creating your own in-game money, 
    demonstrating how to create and manage tokens.
*/

contract MyFirstToken {

    address private iOwner;
    string private iName = "MyFirstTokenERC-20";
    string private iSymbol = "MFTE";
    uint8 private iDecimals = 18;
    uint256 private iTotalSupply;

    mapping (address => uint256) private sBalances;
    mapping (address => mapping (address => uint256)) private sAllowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(uint256 _initSupply) {
        iOwner = msg.sender;
        iTotalSupply = _initSupply * (10 ** uint256(iDecimals));
        sBalances[msg.sender] = iTotalSupply;
        emit Transfer(address(0x0), msg.sender, iTotalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return sBalances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(sBalances[msg.sender] >= _value, "Not enough token balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0) || _to != address(0), "Invalid address");
        require(sBalances[_from] >= _value, "Not enough balance");

        // require(sA);
        sAllowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        sBalances[_from] -= _value;
        sBalances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(sBalances[msg.sender] >= _value, "Not enough token balance");
        sBalances[msg.sender] -= _value;
        sAllowances[_spender][msg.sender] += _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return sAllowances[_spender][_owner];
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