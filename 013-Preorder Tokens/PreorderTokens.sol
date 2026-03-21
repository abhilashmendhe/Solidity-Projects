// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/*
Build a contract to sell your tokens for Ether. You'll learn how to set a price and manage sales, demonstrating token economics. 
It's like a pre-sale for your digital currency, showing how to sell tokens for Ether.
*/

import "./MyMenToken.sol";

contract PreorderTokens is MyMenToken {
    
    address private projectOwner;
    uint256 private tokenPrice;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private minPurchaseAmt;
    uint256 private maxPurchaseAmt;
    uint256 private totalValueRaised;
    bool public finalized = false;
    bool private initialTransferDone = false;
    MyMenToken public myToken;
    
    event PurchasedTokens(address indexed buyer, uint256 tokenAmt, uint256 ethAmt);
    event SaleEnd(uint256 totalValRaised, uint256 totalSoldTokens);

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

    
    function saleRemaingTime() public view returns (uint256) {
        require(block.timestamp <= saleEndTime, "Sale ended");
        return saleEndTime - block.timestamp;
    }
    function availibilityOfTokens() public view returns (uint256) {
        return balanceOf(address(this));
    }
    function totalTokenValueRaised() public view returns (uint256) {
        return totalValueRaised;
    }
    function owner() public view returns(address) {
        return projectOwner;
    }
    
}