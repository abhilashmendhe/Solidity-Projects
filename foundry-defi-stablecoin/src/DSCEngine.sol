// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
 * @notice This contract is the core of DSC System. It handles all the logic for mining and redeeming DSC, as
 * well as depositing & withdrawing collateral.
 * @notice This contract is very loosely based on MakerDAO DSS (DAI) system.
 */


contract DSCEngine {

}