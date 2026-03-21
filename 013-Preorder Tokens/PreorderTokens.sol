// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/*
Build a contract to sell your tokens for Ether. You'll learn how to set a price and manage sales, demonstrating token economics. 
It's like a pre-sale for your digital currency, showing how to sell tokens for Ether.
*/

import "./MyMenToken.sol";

contract PreorderTokens is MyMenToken {
    
    address projectOwner;
    uint256 tokenPrice;
    uint256 saleStartTime;
    uint256 saleEndTime;
    uint256 minPurchaseAmt;
    uint256 maxPurchaseAmt;
    bool public finalized = false;
    bool private initialTransferDone = false;

    constructor(
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _saleDurationInSeconds,
        uint256 _minPurchase,
        uint256 _maxPurchase,
        address _projectOwner
    ) MyMenToken(_initialSupply) {
        
        tokenPrice = _tokenPrice;
        saleStartTime = block.timestamp;
        saleEndTime = block.timestamp + _saleDurationInSeconds;
        minPurchaseAmt = _minPurchase;
        maxPurchaseAmt = _maxPurchase;
        projectOwner = _projectOwner;

        // Transfer token to this contract
        _transfer(msg.sender, address(this), totalSupply());

        initialTransferDone = true;
    }
}