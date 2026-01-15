// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library PriceConverter {

    // price: 3288490455000000000000
    function getPriceETHToUSD() internal pure returns(uint256) {
        return 3288490455000000000000;
    }

    // price: 1164900000000000000
    function getPriceEURToUSD() internal pure returns(uint256) {
        return 1164900000000000000;
    }

    // price: 1342995000000000000
    function getPriceGBPToUSD() internal pure returns(uint256) {
        return 1342995000000000000;
    }

    // price: 667850000000000000
    function getPriceAUDToUSD() internal pure returns(uint256) {
        return 667850000000000000;
    }

    // price: 6303750000000000
    function getPriceJPYToUSD() internal pure returns(uint256) {
        return 6303750000000000;
    }

    function conversionRate(uint256 ethAmt, uint256 currRate, uint256 ETH_USD) internal  pure returns (uint256) {
        // return (SUBMIT_WEI/ETH_WEI) * ETH_USD;
        // uint256 ETH_USD = getPriceETHToUSD();
        return (ethAmt * ETH_USD / currRate) / 1e18;
    }
    function minAmtConversion(uint256 minUSD, uint256 currRate, uint256 ETH_USD) internal pure returns (uint256) {
        // uint256 ETH_USD = getPriceETHToUSD();
        return (minUSD * 1e18) / ((currRate*ETH_USD) / ETH_USD);
    }

    function uintToDecimalString(uint256 value) internal  pure returns (string memory) {
        uint256 integerPart = value / 1e18;
        uint256 fractionalPart = value % 1e18;

        return string(
            abi.encodePacked(
                Strings.toString(integerPart),
                ".",
                Strings.toString(fractionalPart)
            )
        );
}
// ------- Uncomment below when working on mainet/testnet to get dynamic prices ------- 

    // // price: 3288490455000000000000
    // function getPriceETHToUSD() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     return uint256(price * 1e10);
    // }

    // // price: 1164900000000000000
    // function getPriceEURToUSD() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910);
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     return uint256(price * 1e10);
    // }

    // // price: 1342995000000000000
    // function getPriceGBPToUSD() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x91FAB41F5f3bE955963a986366edAcff1aaeaa83);
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     return uint256(price * 1e10);
    // }

    // // price: 667850000000000000
    // function getPriceAUDToUSD() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xB0C712f98daE15264c8E26132BCC91C40aD4d5F9);
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     return uint256(price * 1e10);
    // }

    // // price: 6303750000000000
    // function getPriceJPYToUSD() internal view returns(uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A6af2B75F23831ADc973ce6288e5329F63D86c6);
    //     (,int256 price,,,) = priceFeed.latestRoundData();
    //     return uint256(price * 1e10);
    // }
           
}