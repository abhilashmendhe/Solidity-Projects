// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title  Rebase Token
 * @author Abhilash
 * @notice This is a cross chain rebase token that incentivizes users to deposit into vault and gain interest and rewrads.
 * @notice The interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate that is the global interest rate at the time of depositing.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256, uint256);

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private sInterestRate = 5e10; // 0.05% rate per unit of time(seconds) ->
    mapping(address => uint256) private sUserInterestRate;
    mapping(address => uint256) private sLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    constructor() ERC20("Rebase Token", "RBTT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Sets the new interest rate
     * @param _newInterestRate : The new interest rate to set
     * @dev   Interest can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate > sInterestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(sInterestRate, _newInterestRate);
        }
        sInterestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Get the pricipal balance of user. This is the number of tokens that have currently been minted to the user,
     * not including any interest that has accrued since the last time the user has interacted with the protocol
     * @param _user Address of the user
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mint the users tokens when they dposit into the vault
     * @param _to     : address of the user
     * @param _amount : amount to create tokens
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        sUserInterestRate[_to] = sInterestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the users token when they withdraw from the vault
     * @param _from The user to burn tokens from
     * @param _amount The amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Transfer token from current user to another
     * @param _recipient Address of the recipient who will receive the tokens
     * @param _amount  Number of tokens that will be received
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            sUserInterestRate[_recipient] = sUserInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer token from one user to another
     * @param _sender Address of the sender who will send the tokens
     * @param _recipient Address of the recipient who will receive the tokens
     * @param _amount  Number of tokens that will be received
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            sUserInterestRate[_recipient] = sUserInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Calculate the balance for the user including the interest that has accumulated since the last updated
     * @param _user : balance of the user
     * @return (principal balance) + some interest has accrued
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // 1. Get the current principal balance of the user (the number of tokens that have actually minted to the user)
        // 2. Multiply the pricicpal balance by the interest rate that has accumulated in the time since the balance was last updated

        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdated(_user) / PRECISION_FACTOR;
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update
     * @param _user : Address of the user to compute interest
     * @return linearInterest The interest that has accumulated since the last udpated
     */
    function _calculateUserAccumulatedInterestSinceLastUpdated(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
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

    /**
     * @notice Mint the accrued interest to the user since last time they interacted with the protocol (e.g. burn, mint, transfer)
     * @param _user The user to mint the accrued interest to
     */
    function _mintAccruedInterest(address _user) internal {
        // 1) find their current balance of rebase tokens that have been minted to the user
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // 2) calculate their current balance including any interest. -> balanceOf(_user)
        uint256 currentBalance = balanceOf(_user);
        // 3) calculate number of tokens that need to be minted to the user
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        // 4) Set the users last updated timestamp
        sLastUpdatedTimestamp[_user] = block.timestamp;
        // 5) call _mint to mint the tokens
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the interest rate set in the contract
     * @return Returns the interest rate.
     */
    function getInterestRate() external view returns (uint256) {
        return sInterestRate;
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
