// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

// This contract stores the data and will help users to interact with the business logic from real contracts where the logic lives

import "./SubscriptionStorageLayout.sol";

contract SubscriptionStorageProxy is SubscriptionStorageLayout {

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    constructor(address _logicContract) {
        owner = msg.sender;
        logicContract = _logicContract;
    }

    function upgradeTo(address _newLogicContract) external onlyOwner {
        logicContract = _newLogicContract;
    }

    // this function gets triggered everytime when users try to interact with a function
    fallback() external payable { 
        address implementation = logicContract;
        require(implementation != address(0), "No logic contract found!");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            
            switch result
                case 0 {revert(0, returndatasize())}
                default {return(0, returndatasize())}
        }
    }

    receive() external payable { 
        
    }
}