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

    // -------------  State Variables  ---------------

    uint256 private constant FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private sPriceFeeds; // token to pricefeeds
    mapping(address user => mapping(address token => uint256 amount)) private sCollateralDeposit; // map users address to the amount of token they have
    mapping(address user => uint256 amountDscMinted) private sDSCMinted;

    address[] private sCollateralTokens;

    DecentralizedStableCoin private immutable I_DSC;

    // -------------  Events  -------------
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);

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

    function depositCollateralAndMintDsc() external {}

    /**
     * @notice Follows CEI - Checks, External,
     * @param tokenCollateralAddress: The address of the token to deposit as collateral
     * @param amountCollateral:       The amount of collateral to deposit
     */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
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

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /**
     * @notice Check if the collateral value > DSC amount.
     * @param amountDscToMint: The amount of decentralized stablecoin to mint
     * @notice They must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) {
        sDSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much ($150 DSC, $100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = I_DSC.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    function liquidate() external {}

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
}
