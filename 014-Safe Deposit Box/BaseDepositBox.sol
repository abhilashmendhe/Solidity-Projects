// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "./IDepositBox.sol";

abstract contract BaseDepositBox is IDepositBox {

    address private owner;
    string private secret;
    uint256 private depositTime;

    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    event SecretStored(address indexed owner);

    constructor() {
        owner = msg.sender;
        depositTime = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(address(0) != newOwner, "Invalid address");
        owner = newOwner;
        emit TransferOwnership(msg.sender, newOwner);
    } 

    function storeSecret(string calldata _secret) external virtual override onlyOwner {
        secret = _secret;
        emit SecretStored(msg.sender);
    }

    function getSecret() public view virtual returns (string memory) {
        return secret;
    }

    function getDepositTime() external view virtual override onlyOwner returns (uint256) {
        return depositTime;
    }
}
