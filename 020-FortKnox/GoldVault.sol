// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract GoldVault {

    error GoldVault__EntranceRestricted();
    error GoldVault__DepositValueZero(string);

    enum Status {
        ENTERED,
        NOT_ENTERED
    }
    Status private _status;
    
    mapping (address => uint256) public goldBalance;

    constructor() {
        _status = Status.NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_status == Status.ENTERED) {
            revert GoldVault__EntranceRestricted();
        }
        _status = Status.ENTERED;
        _;
        _status = Status.NOT_ENTERED;
    }

    function deposit() external payable {
        if (msg.value == 0) {
            revert GoldVault__DepositValueZero("Deposit value should be more than zero.");
        }
        goldBalance[msg.sender] += msg.value;
    }

    function unsafeWithdraw() external {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH Transfer Failed");
        goldBalance[msg.sender] = 0;
    }

    function safeWithdraw() external nonReentrant {
        uint256 amount = goldBalance[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        goldBalance[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH Transfer Failed");
    }
}