// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract LendingPool {

    mapping (address=>uint256) public depositBalances;      // how much ETH a user has deposited
    mapping (address=>uint256) public borrowBalances;       // how much ETH a user has borrowed
    /*
    Collateral: property or something valuable that you agree to give to somebody if you cannot pay back money that you have borrowed
    */
    mapping (address=>uint256) public collateralBalances;   // how much ETH a user has added as a collateral
    mapping (address=>uint256) public lastInterestAccuralTimestamp;
    // we record the last time we calculated interest for each user. 
    //Then, whenever the user interacts with the system (borrows, repays, etc.), we check how much time has passed and 
    // calculate how much interest has built up since then.

    uint256 constant public interestRateBasisPoints     = 500;
    uint256 constant public collateralFactorBasisPoints = 7500;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event CollateralDeposit(address indexed user, uint256 amount);
    event CollateralWithdraw(address indexed user,uint256 amount);


    function deposit() external payable {
        require(msg.value > 0, "ETH value should be more than 0");
        depositBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Must withdraw more than 0");
        require(depositBalances[msg.sender]>amount, "Not have enough balance");
        depositBalances[msg.sender] -= amount;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "Failed to transfer ETH from contract to the user");
        emit Withdraw(msg.sender, amount);
    }

    function calculatingInterest(address user) public view returns(uint256) {
        if(borrowBalances[user]==0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastInterestAccuralTimestamp[user];
        uint256 interest = (borrowBalances[user] * interestRateBasisPoints * timeElapsed) / (10000 * 365);
        return borrowBalances[user] + interest;
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "ETH value should be more than 0");
        collateralBalances[msg.sender] += msg.value;
        emit CollateralDeposit(msg.sender, msg.value);
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(collateralBalances[msg.sender] >= amount, "Insufficent balance to withdraw collateral");

        uint256 borrowedAmount = calculatingInterest(msg.sender);
        uint256 requiredCollateral = (borrowedAmount*10000) / collateralFactorBasisPoints;
        require(collateralBalances[msg.sender]-amount >= requiredCollateral, "Withdrawal not possible. It would break collateral ratio");
        collateralBalances[msg.sender] -= amount;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "Failed to transfer ETH from contract to the user");
        emit CollateralWithdraw(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Must borrow more than 0");
        require(address(this).balance >= amount, "Not enough liquidity in the pool");
        uint256 maxBorrowAmount = (collateralBalances[msg.sender] * collateralFactorBasisPoints) / 10000;
        uint256 currentDebt = calculatingInterest(msg.sender);
        require(currentDebt+amount <= maxBorrowAmount, "Exceed allowed borrow amount");
        borrowBalances[msg.sender] = currentDebt + amount;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "Failed to transfer ETH from contract to the user");
        emit Borrow(msg.sender, amount);
        
    }

    function repay() external payable {
        require(msg.value > 0, "Repay value must be greater than 0");
        uint256 currentDebt = calculatingInterest(msg.sender);
        require(currentDebt > 0, "No need to repay");
        uint256 amountToRepay = msg.value;

        if (amountToRepay > currentDebt) {
            amountToRepay = currentDebt;
            (bool success, ) = (msg.sender).call{value: msg.value - currentDebt}("");
            require(success, "Failed to transfer ETH from contract to the user");
            emit CollateralWithdraw(msg.sender, amountToRepay);
        }
        borrowBalances[msg.sender] = currentDebt - amountToRepay;
        lastInterestAccuralTimestamp[msg.sender] = block.timestamp;

        emit Repay(msg.sender, amountToRepay);
    }

    function getMaxBorrowAmount(address user) external view returns(uint256) {
        return (collateralBalances[user] * collateralFactorBasisPoints) / 10000;
    }

    function getLiquidity() external view returns(uint256) {
        return address(this).balance;   // how much the lending pool ETH holds
    }
}