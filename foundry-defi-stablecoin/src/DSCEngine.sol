// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

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
    
    // -------------  State Variables  ---------------
    mapping(address token => address priceFeed) private sPriceFeeds; // token to pricefeeds
    mapping(address user => mapping(address token => uint256 amount)) private sCollateralDeposit; // map users address to the amount of token they have
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

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
