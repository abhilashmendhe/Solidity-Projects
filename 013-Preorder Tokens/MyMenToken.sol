// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyMenToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyMenToken", "MMETK") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}
