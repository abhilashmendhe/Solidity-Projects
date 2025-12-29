// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // this is the solidity version

/*
    Create a basic auction! Users can bid on an item, and the highest bidder wins when time runs out. 
    You'll use 'if/else' to decide who wins based on the highest bid and track time using the blockchain's clock (`block.timestamp`). 
    This is like a simple version of eBay on the blockchain, showing how to control logic based on conditions and time.
*/

contract AuctionHouse {
    struct BidderInfo {
        address bidder;
        uint256 amount;
    }
    struct BidItem {
        address owner;
        string itemName;
        string itemInfo;
        uint256 bidEndTime;
        BidderInfo[] bidders;
    }
    
    BidItem[] bidItems;
    
    function createBid(string memory _itemName, string memory _itemInfo, uint256 _days, uint256 _hours, uint256 _mins, uint256 _secs) public {
        
        uint256 _bidEndTime = block.timestamp + (_days * 1 days) + (_hours * 1 hours) + (_mins * 1 minutes) + (_secs * 1 seconds);
        require(_bidEndTime <= (block.timestamp + 432000), "Bidding time should be less than 5 days.");
        
        bidItems.push();
        BidItem storage newBidItem = bidItems[bidItems.length - 1];
        newBidItem.owner = msg.sender;
        newBidItem.itemName = _itemName;
        newBidItem.itemInfo = _itemInfo;
        newBidItem.bidEndTime = _bidEndTime;
    }

    function getBidItem(uint256 _index) public view returns (BidItem memory) {
        require(_index < bidItems.length, "Invalid bid item index value!");
        return bidItems[_index];
    }
    
    function getAllBidItems() public view returns (BidItem[] memory) {
        return bidItems;
    }

    function bidOnItem(uint256 _index, uint256 amount) public {
        require(_index < bidItems.length, "Invalid bid item index value!");
        
        BidItem storage bidItem = bidItems[_index];

        require(msg.sender != bidItem.owner, "Owner can't bid on their own items.");
        require(block.timestamp < bidItem.bidEndTime, "Bid time closed. Can't bid on the item anymore.");
        
        BidderInfo memory newBidder = BidderInfo(msg.sender, amount);
        bidItem.bidders.push(newBidder);
    }

    function unBidOnItem(uint256 _index) public returns (string memory){
        require(_index < bidItems.length, "Invalid bid item index value!");
        
        BidItem storage bidItem = bidItems[_index];

        require(block.timestamp < bidItem.bidEndTime, "Bid time closed. Can't unbid on the item anymore.");
        
        bool bidderFound = false;
        uint bidInd = 0;
        for (uint256 i=0; i< bidItem.bidders.length; i++) {
            if (msg.sender == bidItem.bidders[i].bidder) {
                bidderFound = true;
                bidInd = i;
                break;
            }
        }
        if (bidderFound) {
            bidItem.bidders[bidInd] = bidItem.bidders[bidItem.bidders.length-1];
            bidItem.bidders.pop();
            return "Succesfully un-bid";
        } else {
            return "Bidder not found. Can't un-bid";
        }
    }

}