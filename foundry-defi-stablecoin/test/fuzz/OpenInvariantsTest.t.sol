// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

// // What are our invariants?

// // 1. The total supply of DSC should be less than the total value of collateral
// // 2. Getter view functions should never revert <- evergreen invariant

// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {ERC20Mock} from "../../test/mocks/ERC20Mock.sol";
// import {console} from "forge-std/console.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract OpenInvariantTest is StdInvariant, Test {

//     DeployDSC deployer;
//     DSCEngine dscEngine;
//     DecentralizedStableCoin dsc;
//     HelperConfig config;
//     address wEth;
//     address wBtc;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dscEngine, config) = deployer.run();
//         targetContract(address(dscEngine));
//         (, , wEth, wBtc,) = config.activeNetworkConfig();

//         // ERC20Mock(wEth).mint(user, STARTING_ERC20_BALANCE);
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
//         // get the value of all the collateral from the protocol
//         // compare it to all the debt (dsc)
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(wEth).balanceOf(address(dscEngine));
//         uint256 totalWbtcDeposited = IERC20(wBtc).balanceOf(address(dscEngine));

//         uint256 wEthValue = dscEngine.getUsdValue(wEth, totalWethDeposited);
//         uint256 wBtcValue = dscEngine.getUsdValue(wBtc, totalWbtcDeposited);

//         console.log("weth value: ", wEthValue);
//         console.log("wbtc value: ", wBtcValue);
//         assert(wEthValue + wBtcValue >= totalSupply);
//     }
// }
