// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "./BaseDepositBox.sol";

contract PremiumDepositBox is BaseDepositBox {

    string private metadata;
    
    event UpdatedMetadata(address indexed owner);

    function getBoxType() external pure override returns(string memory) {
        return "Premium Deposit Box";
    }

    function setMetadata(string calldata _metadata) external onlyOwner {
        metadata = _metadata;
        emit UpdatedMetadata(msg.sender);
    }

    function getMetaData() external view onlyOwner returns(string memory) {
        return metadata;
    }
}