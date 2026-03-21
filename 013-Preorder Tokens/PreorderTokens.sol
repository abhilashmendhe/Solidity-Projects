// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/*
Build a contract to sell your tokens for Ether. You'll learn how to set a price and manage sales, demonstrating token economics. 
It's like a pre-sale for your digital currency, showing how to sell tokens for Ether.
*/

import "./MyMenToken.sol";

contract PreorderTokens is MyMenToken {
    
    // 1. Owner of the project. (who deployed this contract)
    address private projectOwner; 

    // 2. Price of an individual token (ex. 0.001 ETH of our created token). Price should be in `wei`
    uint256 private tokenPrice;

    // 3. Stores the start of the sale time
    uint256 private saleStartTime;

    // 4. Stores the end of the sale time
    uint256 private saleEndTime;

    // 5. Stores the min `wei` purchase amount value. Buying price should be more than minPurchaseAmt.
    uint256 private minPurchaseAmt;

    // 6. Stores the max `wei` purchase amount value. Buying price should be less than maxPurchaseAmt.
    uint256 private maxPurchaseAmt;

    // 7. Stores the total value of price of purchased tokens
    uint256 private totalValueRaised;

    // 8. Variable to determine if sale ended or not
    bool public finalized = false;

    // 9. Variable indicates if the initial transfer was done from owner to contract.
    bool private initialTransferDone = false;


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
    
    function isSaleActive() public view returns (bool) {
        return (!finalized && (block.timestamp <= saleEndTime && block.timestamp >= saleStartTime));
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

    function purchaseToken() public payable {

        // 1. Calculate the token amount to send to users
        uint256 tokenAmt = (msg.value * (10**decimals())) / tokenPrice;

        // 2. Update total value raised. (update the total amount of the purchased tokens by multiple users)
        totalValueRaised += msg.value;

        // 3. Make transfer
        _transfer(address(this), msg.sender, tokenAmt);
        emit PurchasedTokens(msg.sender, tokenAmt, msg.value);
    }
    
    function endSale() public payable {

        //  1. Set finalized to true to indicate that sale as ended.
        finalized = true;
        
        // 2. Get the remaining token left which were not sold.
        uint256 soldTokens = totalSupply() - balanceOf(address(this));

        // 3. Transfer the total value raised so far for the sold token.
        (bool success, ) = projectOwner.call{value: address(this).balance}("");
        require(success, "Transfer to owner failed.");

        emit SaleEnd(totalValueRaised, soldTokens);
    }
}