// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {
    constructor() ERC20("TokenA", "TA") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1 million tokens to you
    }
}