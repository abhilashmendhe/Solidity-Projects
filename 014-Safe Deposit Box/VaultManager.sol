// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import "./IDepositBox.sol";
import "./BasicDepositBox.sol";
import "./PremiumDepositBox.sol";
import "./TimeLockedDepositBox.sol";

contract VaultManager {

    mapping (address => address[]) private userDepositBoxes;
    mapping (address => string) private boxNames;

    event BoxCreated(address indexed owner, address indexed boxAddress, string boxType);
    event BoxNamed(address indexed boxAddress, string boxName);

    function createBasicBox() external returns (address) {
        BasicDepositBox basicDepositBox = new BasicDepositBox();
        userDepositBoxes[msg.sender].push(address(basicDepositBox));
        emit BoxCreated(msg.sender, address(basicDepositBox), "basic");
        return address(basicDepositBox);
    }

    function createPremiumBox() external returns (address) {
        PremiumDepositBox premiumDepositBox = new PremiumDepositBox();
        userDepositBoxes[msg.sender].push(address(premiumDepositBox));
        emit BoxCreated(msg.sender, address(premiumDepositBox), "premium");
        return address(premiumDepositBox);
    }

    function createTimeLockedBox(uint256 lockDuration) external returns (address) {
        TimeLockedDepositBox timeLockedDepositBox = new TimeLockedDepositBox(lockDuration);
        userDepositBoxes[msg.sender].push(address(timeLockedDepositBox));
        emit BoxCreated(msg.sender, address(timeLockedDepositBox), "time locked");
        return address(timeLockedDepositBox);
    }

    function nameBox(address boxAddress, string memory name) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner()==msg.sender, "Not the owner of the box");

        boxNames[boxAddress] = name;
        emit BoxNamed(boxAddress, name);
    }

    function storeSecret(address boxAddress, string calldata secret) external {
        IDepositBox box = IDepositBox(boxAddress);
        require(box.getOwner()==msg.sender, "Not the owner of the box");
        box.storeSecret(secret);
    }

    function transferOwnership(address _boxAddress, address _newOwner) external {
        
        IDepositBox box = IDepositBox(_boxAddress);
        require(box.getOwner()==msg.sender, "Not the box owner");

        box.transferOwnership(_newOwner);

        // delete vault from userdepositboxes
        address[] storage boxes = userDepositBoxes[msg.sender];
        for(uint256 i=0; i<boxes.length; i++) {
            if (boxes[i] == _boxAddress) {
                boxes[i] = boxes[boxes.length-1];
                boxes.pop();
                break;
            }
        }

        userDepositBoxes[_newOwner].push(_boxAddress);
    }

    function getUserBoxes() external view returns (address[] memory) {
        return userDepositBoxes[msg.sender];
    }

    function getBoxName(address boxAddress) external view returns (string memory) {
        return boxNames[boxAddress];
    }

    function getBoxInfor(address _boxAddress) external view returns (string memory boxType, address owner, uint256 depoitTime, string memory name) {
        IDepositBox box = IDepositBox(_boxAddress);
        return (box.getBoxType(), box.getOwner(), box.getDepositTime(), boxNames[_boxAddress]);
    } 
}