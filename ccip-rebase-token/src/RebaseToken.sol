// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title  Rebase Token
 * @author Abhilash
 * @notice This is a cross chain rebase token that incentivizes users to deposit into vault and gain interest and rewrads.
 * @notice The interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate that is the global interest rate at the time of depositing.
 */
contract RebaseToken is ERC20 {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256, uint256);

    uint256 private constant PRECISION_FACTOR = 1e18;

    uint256 private sInterestRate = 5e10; // 0.05% rate per unit of time(seconds) ->
    mapping(address => uint256) private sUserInterestRate;
    mapping(address => uint256) private sLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    constructor() ERC20("Rebase Token", "RBTT") {}

    /**
     * @notice Sets the new interest rate
     * @param _newInterestRate : The new interest rate to set
     * @dev   Interest can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate > sInterestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(sInterestRate, _newInterestRate);
        }
        sInterestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the users tokens when they dposit into the vault
     * @param _to     : address of the user
     * @param _amount : amount to create tokens
     */
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        sUserInterestRate[_to] = sInterestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Calculate the balance for the user including the interest that has accumulated since the last updated
     * @param _user : balance of the user
     * @return (principal balance) + some interest has accrued
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // 1. Get the current principal balance of the user (the number of tokens that have actually minted to the user)
        // 2. Multiply the pricicpal balance by the interest rate that has accumulated in the time since the balance was last updated

        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdated(_user);
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user Address of the user to compute interest
     * @return The interest that has accumulated since the last udpated
     */
    function _calculateUserAccumulatedInterestSinceLastUpdated(address _user) internal view returns (uint256 linearInterest) {
        // We need to calcualte the interest that has accumulated since the last update
        // This is going to be linear growth in time.
        // 1. Calculate the time since the last update
        // 2. Calculate the amount of linear growth
        
        // e.g. 
        // Deposit: 10 tokens
        // Interest rate: 0.5 tokens per second
        // time elapsed is 2 seconds
        // Deposit + (Deposit * interest rate * time elapsed)
        // 10 + (10 * 0.5 * 2) = 21

        uint256 timeElapsed = block.timestamp - sLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (sUserInterestRate[_user] * timeElapsed);
        return linearInterest;
    }

    function _mintAccruedInterest(address _user) internal {
        // 1) find their current balance of rebase tokens that have been minted to the user
        // 2) calculate their current balance including any interest. -> balanceOf(_user)
        // 3) calculate number of tokens that need to be minted to the user
        // 4) call _mint to mint the tokens
        // 5) Set the users last updated timestamp
        sLastUpdatedTimestamp[_user] = block.timestamp;
    }

    /**
     * @notice Get the interest rate of the user
     * @param  _user   : Address of the user to fetch its interest rate
     * @return uint256 : Returns the interest rate of the user
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return sUserInterestRate[_user];
    }
}
