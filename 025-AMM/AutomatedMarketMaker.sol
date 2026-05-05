// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

/*
    Build a system for trading tokens automatically. You'll learn how to create liquidity pools and implement 
    the constant product formula, demonstrating AMM logic. It's like a digital exchange for tokens, showing 
    how to create automated markets.
*/

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AutomatedMarketMaker is ERC20 {

    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reservedA;
    uint256 public reservedB;

    address public owner;
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokenSwapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(_tokenA != _tokenB, "Both address should be different");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

    // babylonian sqrt func
    function sqrt(uint256 y) internal pure returns(uint256 z) {
        if (y <= 3) {
            z = 1;
        } else {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y/x + x) / 2;
            }
        }
    }

    function addLiquidate(uint256 _amtA, uint256 _amtB) public {
        require(_amtA > 0 && _amtB > 0, "Amount for token A and B should be greater than 0!");
        tokenA.transferFrom(msg.sender, address(this), _amtA);
        tokenB.transferFrom(msg.sender, address(this), _amtB);

        uint256 liquidity; 
        if (totalSupply() == 0) {
            liquidity = sqrt(_amtA * _amtB);
        } else {
            liquidity = min(_amtA * totalSupply() / reservedA, _amtB * totalSupply() / reservedB);
        }

        _mint(msg.sender, liquidity);
        reservedA += _amtA;
        reservedB += _amtB;

        emit LiquidityAdded(msg.sender, _amtA, _amtB, liquidity);
    }

    function removeLiquidity(uint256 liquidityToRemove) external returns (uint256 amountAOut, uint256 amountBOut) {
        require(liquidityToRemove > 0,"Must be greater than 0");
        require(balanceOf(msg.sender) == liquidityToRemove, "Insufficient amount");

        uint256 totalLiquidity = totalSupply();
        require(totalLiquidity > 0, "No liquidity in the pool");

        amountAOut = (liquidityToRemove * reservedA) / totalLiquidity;
        amountBOut = (liquidityToRemove * reservedB) / totalLiquidity;

        require(amountAOut > 0 && amountBOut > 0, "Insufficient reserves for requested liquidity");
        reservedA -= amountAOut;
        reservedB -= amountBOut;

        _burn(msg.sender, liquidityToRemove);

        tokenA.transfer(msg.sender, amountAOut);
        tokenB.transfer(msg.sender, amountBOut);

        emit LiquidityRemoved(msg.sender, amountAOut, amountBOut, liquidityToRemove);
    }

    function swapAForB(uint256 amountAIn, uint256 minBOut) external {
        require(amountAIn > 0, "Amount must be greater than 0");
        require(reservedA > 0 && reservedB > 0, "Insufficient reserves");

        uint256 amountAInWithFee = amountAIn * 997 / 1000;
        uint256 amountBOut = reservedB * amountAInWithFee / (reservedA + amountAInWithFee);
        require(amountBOut >= minBOut, "Slippage too high");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender,  amountBOut);
        reservedA += amountAInWithFee;
        reservedB -= amountBOut;

        emit TokenSwapped(msg.sender, address(tokenA), amountAIn, address(tokenB), amountBOut);
    }

    function swapBForA(uint256 amountBIn, uint256 minAOut) external {
        require(amountBIn > 0, "Amount must be greater than 0");
        require(reservedA > 0 && reservedB > 0, "Insufficient reserves");

        uint256 amountBInWithFee = amountBIn * 997 / 1000;
        uint256 amountAOut = reservedA * amountBInWithFee / (reservedB + amountBInWithFee);
        require(amountAOut >= minAOut, "Slippage too high");

        tokenA.transferFrom(msg.sender, address(this), amountBIn);
        tokenB.transfer(msg.sender, amountAOut);
        reservedB += amountBInWithFee;
        reservedA -= amountAOut;

        emit TokenSwapped(msg.sender, address(tokenB), amountBIn, address(tokenA), amountAOut);
    }

    function getReserves() external view returns(uint256, uint256) {
        return (reservedA, reservedB);
    }
}