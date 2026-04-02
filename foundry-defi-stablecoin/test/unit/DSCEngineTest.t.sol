// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../../test/mocks/ERC20Mock.sol";
import {console} from "forge-std/console.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address wEth;
    address wBtc;

    uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    address public user = makeAddr("user");

    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, wEth, wBtc,) = config.activeNetworkConfig();

        ERC20Mock(wEth).mint(user, STARTING_ERC20_BALANCE);
    }

    // ----------------  Constructor Tests  ----------------
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthMismatchPriceFeeds() public {
        tokenAddresses.push(wEth);
        // tokenAddresses.push(wBtc); // Make sure to comment this so the test can pass
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressAndPriceFeedAddressMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        // new DSCEngine
    }

    // ----------------  Price Tests  ----------------
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/ETH = 30,000e18;

        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValue(wEth, ethAmount);
        assert(expectedUsd == actualUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        // $2000 / ETH, $100 => $100 / $ 2000 ETH = 0.05 ETH = 50000000000000000 wei
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(wEth, usdAmount);
        assert(expectedWeth == actualWeth);
        // console.log(actualWeth, expectedWeth);
    }

    // ----------------  depositCollateral Tests  -----------------
    function testRevertIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dscEngine), amountCollateral);

        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        dscEngine.depositCollateral(wEth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RANAA", user, amountCollateral);
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(ranToken), amountCollateral);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(wEth).approve(address(dscEngine), amountCollateral);
        dscEngine.depositCollateral(wEth, amountCollateral);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(user);

        // 10 eth * 2000 = 20,000
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(wEth, collateralValueInUsd);

        assert(totalDscMinted == expectedTotalDscMinted);
        assert(amountCollateral == expectedDepositAmount);
    }
}
