// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract Ownable {

    error Ownable__InvalidAddress();
    // error Ownable__NotOwner();

    address private _owner;

    event TransferOwnership(address indexed from, address indexed to);

    constructor() {
        _owner = msg.sender;
        emit TransferOwnership(address(0), _owner);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Owner of the contract can perform this operation");
        _;
    }

    function ownerAddress() public view returns(address) {
        return _owner;
    }

    function transferOwnershipFunc(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address is invalid");
        if (newOwner == address(0)) {
            revert Ownable__InvalidAddress();
        }
        address prevOwner = _owner;
        _owner = newOwner;
        emit TransferOwnership(prevOwner, _owner);
    }
}