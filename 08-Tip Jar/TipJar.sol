// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
    Build a multi-currency digital tip jar! Users can send Ether directly or simulate tips in foreign currencies like USD or EUR. 
    You'll learn how to manage currency conversion, handle Ether payments using `payable` and `msg.value`, and keep track of individual contributions. 
    Think of it like an advanced version of a 'Buy Me a Coffee' button — but smarter, more global, and Solidity-powered.
*/
import "@openzeppelin/contracts/utils/Strings.sol";
import {PriceConverter} from "./PriceConverterHelper.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
error NotOwner();

contract TipJar {

    uint256 constant MIN_USD = 5 * 1e18;
    // uint256 constant ETH_WEI = 1000000000000000000;
    // uint256 constant SUBMIT_WEI = 400000000000000; //1330800000000000000

    address private immutable iOwner;

    struct Tipper {
        address tipperAddr;
        uint256 donationAmt;
    }

    Tipper[] private tippers;
    // mapping (address => uint256) private tippersDonationAmt;

    constructor() {
        iOwner = msg.sender;
    }
    function _onlyOwner() internal view {
        if (msg.sender != iOwner) revert NotOwner();
        
    }
    modifier onlyOnwer() {
        _onlyOwner();
        _;
    }
    function getOwner() public view onlyOnwer returns(address) {
        return iOwner;
    }

    modifier onlyTipper() {
        require(msg.sender != iOwner, "Onwer can't fund itself.");
        _;
    }

    function viewTippers() public view onlyOnwer returns(Tipper[] memory) {
        return tippers;
    }
    
    function tip(string memory currency) public payable onlyTipper minCurrency(currency) {
        
        tippers.push(Tipper(msg.sender, msg.value));
    }

    modifier minCurrency(string memory currency){
        
        bytes32 curr_str = keccak256(abi.encodePacked(currency));
        uint256 ETH_USD = PriceConverter.getPriceETHToUSD();

        if (curr_str == keccak256(abi.encodePacked("GBP")) || curr_str == keccak256(abi.encodePacked("gbp")) ) {

            uint256 GBP_USD = PriceConverter.getPriceGBPToUSD();
            uint256 MIN_GBP = PriceConverter.minAmtConversion(MIN_USD, GBP_USD, ETH_USD);
            uint256 MIN_WEI = MIN_GBP / (ETH_USD / GBP_USD);
            require(msg.value >= MIN_WEI, string(abi.encodePacked("Min ", PriceConverter.uintToDecimalString(MIN_GBP), " GBP or ", Strings.toString(MIN_WEI), " wei is required to tip")));
        } else if (curr_str == keccak256(abi.encodePacked("EUR")) || curr_str == keccak256(abi.encodePacked("eur")) ) {

            uint256 EUR_USD = PriceConverter.getPriceEURToUSD();
            uint256 MIN_EUR = PriceConverter.minAmtConversion(MIN_USD, EUR_USD, ETH_USD);
            uint256 MIN_WEI = MIN_EUR / (ETH_USD/EUR_USD);
            require(msg.value >= MIN_WEI, string(abi.encodePacked("Min ", PriceConverter.uintToDecimalString(MIN_EUR), " EUR or ", Strings.toString(MIN_WEI), " wei is required to tip")));
        } else if (curr_str == keccak256(abi.encodePacked("JPY")) || curr_str == keccak256(abi.encodePacked("jpy")) ) {

            uint256 JPY_USD = PriceConverter.getPriceJPYToUSD();
            uint256 MIN_JPY = PriceConverter.minAmtConversion(MIN_USD, JPY_USD, ETH_USD);
            uint256 MIN_WEI = MIN_JPY / (ETH_USD/JPY_USD);
            require(msg.value >= MIN_WEI, string(abi.encodePacked("Min ", PriceConverter.uintToDecimalString(MIN_JPY), " JPY or ", Strings.toString(MIN_WEI), " wei is required to tip")));
        } else if (curr_str == keccak256(abi.encodePacked("AUD")) || curr_str == keccak256(abi.encodePacked("aud")) ) {

            uint256 AUD_USD = PriceConverter.getPriceAUDToUSD();
            uint256 MIN_AUD = PriceConverter.minAmtConversion(MIN_USD, AUD_USD, ETH_USD);
            uint256 MIN_WEI = MIN_AUD / (ETH_USD/AUD_USD);
            require(msg.value >= MIN_WEI, string(abi.encodePacked("Min ", PriceConverter.uintToDecimalString(MIN_AUD), " AUD or ", Strings.toString(MIN_WEI), " wei is required to tip")));
        } else {

            uint256 send_amt = PriceConverter.conversionRate(msg.value, 1, ETH_USD);
            uint256 MIN_WEI = (MIN_USD*1e18)/ETH_USD;
            require(send_amt >= MIN_WEI, string(abi.encodePacked("Min ", PriceConverter.uintToDecimalString(MIN_USD), " USD or ",Strings.toString(MIN_WEI)," wei is required to tip")));
        }
        _;
    }

    function withdraw() public onlyOnwer payable {
        require(tippers.length > 0, "No tips are there to withdraw.");
        delete tippers;
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Withdraw Failed.");
    }
}