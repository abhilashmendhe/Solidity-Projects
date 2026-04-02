# Building DeFI protocol

1. (Relative stability) Anchored or Pegged -> $1.00
    1. Chainlink price feed.
    2. Set a function to exchange ETH & BTC -> $$$
2. Stability mechanism (minting): Algorithmic (Decentralized)
    1. People can only mint the stableoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    1. wETH (ERC20 version of ETH)
    2. wBTC (ERC20 version of BTC)

 - Calculated health factor function
 - Set health factor if debt is 0
 - Added a bunch of view function

 1. What are our invariants/properties?
 
<!-- # Layout of contract -->
<!-- // Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions -->