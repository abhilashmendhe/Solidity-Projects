// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Abhilash Mendhe
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg.
 * This stable coin has properties:
 * - Exogenous Collateral
 * - Dollar pegged
 * - Algorithmic Stable
 *
 * It is similar to DAI, if DAI had no governance, no fees, and was only backed by wETH and wBTC
 *
 * Our DSC system should always be "overcollateralized". At no point, should the
 * value of all collateral <= the $ backed value of all the DSC.
 *
 * @notice This contract is the core of DSC System. It handles all the logic for mining and redeeming DSC, as
 * well as depositing & withdrawing collateral.
 * @notice This contract is very loosely based on MakerDAO DSS (DAI) system.
 *
 *     // Ex 1.
 *     // Threshold to let's say 150%
 *     // $100 ETH -> $75 ETH
 *     // $ 50 DSC
 *
 *     // Hey if someone pays back your minted DSC, they can have all your collateral for a discount.
 *
 *     // Ex 2.
 *     // Threshold to let's say 150%
 *     // If I put down $100 of ETH as collateral, -> price of my ETH tanks to $74
 *     // And I mint $50 DSC
 *     // Other sees, I am under collateralized, we let other users liquidate.
 *
 *     // I will payback $50 DSC -> Get all your collateral to other user
 *
 *     // If now I've $0 worth of ETH, and another user got $74. I will pay -$50 DSC. The other user will liquidate $24.
 */

contract DSCEngine is ReentrancyGuard {
    // -------------  Errors  ---------------
    error DSCEngine__NeedMoreThanZero();
    error DSCEngine__TokenAddressAndPriceFeedAddressMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine_TransferFailed();
    error DSCEngine__HealthFactorIsBelowMinimum(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImporved();

    // -------------  State Variables  ---------------

    uint256 private constant FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; // 10% bonus

    mapping(address token => address priceFeed) private sPriceFeeds; // token to pricefeeds
    mapping(address user => mapping(address token => uint256 amount)) private sCollateralDeposit; // map users address to the amount of token they have
    mapping(address user => uint256 amountDscMinted) private sDSCMinted;

    address[] private sCollateralTokens;

    DecentralizedStableCoin private immutable I_DSC;

    // -------------  Events  -------------
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    // -------------  Modifiers  ---------------
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (sPriceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    // -------------  Constructor  -------------
    constructor(address[] memory tokenAddress, address[] memory priceFeedAddress, address dscAddress) {
        // USD Price Feeds
        if (tokenAddress.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressAndPriceFeedAddressMustBeSameLength();
        }

        // e.g. ETH / USD, BTC / USD, MKR / USD etc.
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            sPriceFeeds[tokenAddress[i]] = priceFeedAddress[i];
            sCollateralTokens.push(tokenAddress[i]);
        }

        I_DSC = DecentralizedStableCoin(dscAddress);
    }

    /**
     *
     * @param tokenCollateralAddress - The address of the token to deposit as collateral
     * @param amountCollateral       - The amount collateral to deposit
     * @param amountDscToMint        - The amount of decentralized stablecoin to mint
     *
     * @notice This function will deposit your collateral and mint DSC in one transaction.
     */
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @notice Follows CEI - Checks, External,
     * @param tokenCollateralAddress: The address of the token to deposit as collateral
     * @param amountCollateral:       The amount of collateral to deposit
     */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        sCollateralDeposit[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    /**
     * @param tokenCollateralAddress - The collateral address to redeem
     * @param amountCollateral       - The amount collateral to redeem
     * @param amountDscToBurn        - The amount of DSC to burn
     *
     * This function burns DSC and redeems the underlying collateral
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    // In order to redeem collateral:
    // 1. Health factor must be over 1 AFTER collateral pulled
    // Writing more modular: DRY (Don't repeat yourself)
    // CEI (check, effects, & interactions)
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        // 100 - 1000 (revert automatically on solidiyt)
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // Let's say I buy $100 ETH worth of $20 DSC
    // If i go back, like giving $20 DSC and want to get $100 ETH, then it will break the health factor
    // I need to:
    // 1. burn DSC
    // 2. redeem ETH

    /**
     * @notice Check if the collateral value > DSC amount.
     * @param amountDscToMint: The amount of decentralized stablecoin to mint
     * @notice They must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) {
        sDSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much ($150 DSC, $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = I_DSC.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // If we come to near undercollateralization, we need to liquidate positions
    // $100 ETH backing $50 DSC
    // $20 ETH backing $50 DSC <- DSC isn't worth $1!!

    // $75 backing $50 DSC
    // Liquidator take $75  bacing and burns(pays) off $50 DSC

    // If someone is almost undercollateralized, we will pay you to liquidate them!

    // We want to make sure that our protocol stays collateralize.

    /**
     * @param collateral  : The erc20 collateral address to liquidate from the user
     * @param user        : The user who has broken the health factor. Their healt factor should be below MIN_HEALTH_FACTOR
     * @param debtToCover : The amount of DSC you want to burn to improve the users health factor.
     *
     * @notice You can partially liquidate a user.
     * @notice You will get liquidation bonus for taking users funds.
     * @notice This function working assumes the protocol will be roughly 200% overcollateralized in order for this to work.
     * @notice A know bug would be if the protocol were 100% or less collateralized, then we wouldn't be able to incentive the liquidators.
     *
     * For e.g. If the price of the collateral plummeted before anyone could be liquidated.
     *
     * Follows CEI: Checks, Effects, Interaction
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // need to check the health factor of the user. If the user is even liquidatable
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        // We want to burn their DSC "debt", and take their collateral
        // Bad User: $140 ETH deposited, $100 DSC
        // debtToCover = $100
        // $100 of DSC == ?? ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // And give them a 10% bonus
        // So we are giving the liquidator $110 of wETH for 100 DSC
        // We should implement a feature to liquidate in the event the protocol is insolvent
        // And sweep extra amounts into the treasury

        // 0.05 ETH * .1 = 0.005 ETH. Getting bonus collateral of 0.055 ETH
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        // Getting bonus collateral of 0.055 ETH
        uint256 totalCollateralToReedem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(user, msg.sender, collateral, totalCollateralToReedem);

        // We need to burn DSC
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImporved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor() external view {}

    // --------------  Private & Internal Functions  --------------

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = sDSCMinted[user];

        // math
        collateralValueInUsd = getAccountCollateralValueInUsd(user);
    }

    /**
     *
     * @param user : address of the user
     *
     * Returns how close to liquidation a user is. If a user goes below 1, then they can get
     * liquidated.
     */
    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral value

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);

        // 1000 ETH * 50 = 50000 / 100 = 500
        // e.g. $1000 ETH / 100 DSC (1000 ETH deposited with 100 DSC minted)
        // 1000 * 50 = 50,000 / 100 = (500 / 100) > 1 (will have health factor of 500)
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check health factor (do they have enough collateral?)
        uint256 userHealthFactor = _healthFactor(user);

        // 2. Revert if they don't have
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsBelowMinimum(userHealthFactor);
        }
    }

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        private
    {
        // 100 - 1000 (revert automatically on solidiyt)
        sCollateralDeposit[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);

        // calculate health factor after
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    /**
     *
     * @param amountDscToBurn : Amount of DSC will be burned
     * @param onBehalfOf      : Address of the user who
     * @param dscFrom         : Address from DSC owner
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        sDSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = I_DSC.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
        I_DSC.burn(amountDscToBurn);
    }

    // --------------  Public & External View Functions  --------------

    function getAccountCollateralValueInUsd(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token,
        // get the amount they have deposited, and map it to the price
        // to get the USD value
        for (uint256 i = 0; i < sCollateralTokens.length; i++) {
            address token = sCollateralTokens[i];
            uint256 amount = sCollateralDeposit[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(sPriceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        return ((uint256(price) * FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        // price of ETH (token)
        // $

        AggregatorV3Interface priceFeed = AggregatorV3Interface(sPriceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();

        // e.g. ($10e18 * 1e18) / ($2000e8 * 1e10)
        return (usdAmountInWei * PRECISION) / (uint256(price) * FEED_PRECISION);
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getAdditionalFeedPrecision() external pure returns (uint256) {
        return FEED_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return sCollateralTokens;
    }

    function getDsc() external view returns (address) {
        return address(I_DSC);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return sPriceFeeds[token];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function getCollateralBalanceOfUser(address user, address token) external view returns (uint256) {
        return sCollateralDeposit[user][token];
    }
}
