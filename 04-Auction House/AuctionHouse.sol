// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version

/*
    Create a basic auction! Users can bid on an item, and the highest bidder wins when time runs out. 
    You'll use 'if/else' to decide who wins based on the highest bid and track time using the blockchain's clock (`block.timestamp`). 
    This is like a simple version of eBay on the blockchain, showing how to control logic based on conditions and time.
*/

contract AuctionHouse {

    struct BidItem {
        address owner;
        string itemName;
        string itemInfo;
        uint256 bidEndTime;
    }

    BidItem[] bidItems;

    function createBid(string memory _itemName, string memory _itemInfo, uint256 _days, uint256 _hours, uint256 _mins, uint256 _secs) public {
        
        uint256 _bidEndTime = block.timestamp + (_days * 1 days) + (_hours * 1 hours) + (_mins * 1 minutes) + (_secs * 1 seconds);
        require(_bidEndTime <= (block.timestamp + 432000), "Bidding time should be less than 5 days.");
        BidItem memory newBidItem = BidItem(msg.sender, _itemName, _itemInfo, _bidEndTime);
        bidItems.push(newBidItem);
    }

    function getBidItem(uint256 _index) public view returns (BidItem memory) {
        require(_index < bidItems.length, "Invalid index value!");
        return bidItems[_index];
    }
    
    function getAllBidItems() public view returns (BidItem[] memory) {
        return bidItems;
    }



}