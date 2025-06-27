// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./libraries/LibErrors.sol";
import {LibMath} from "./libraries/LibMath.sol";

/// @title SkySwapPool
/// @notice Implements the custom oracle-anchored invariant for SkySwap (see .cursor/rules/uniswap-v4-hooks.md)
contract SkySwapPool {
    // --- State ---
    address public owner;
    address public skySwapHooks;
    
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public invariant;
    uint256 public oraclePrice;
    
    // Pool parameters - amplification constant fixed by governance
    uint256 public constant A = 300; // Fixed amplification constant
    uint256 public totalLiquidity;

    // --- Events ---
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);
    event InvariantUpdated(uint256 newInvariant);
    event OraclePriceUpdated(uint256 newOraclePrice);
    event ReservesUpdated(uint256 reserve0, uint256 reserve1);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    modifier onlyHook() {
        if (msg.sender != skySwapHooks) revert LibErrors.OnlyHook();
        _;
    }

    constructor(uint256 _initialOraclePrice) {
        owner = msg.sender;
        oraclePrice = _initialOraclePrice;
    }

    function setSkySwapHooks(address _skySwapHooks) external onlyOwner {
        if (_skySwapHooks == address(0)) revert LibErrors.ZeroAddress();
        skySwapHooks = _skySwapHooks;
    }

    // --- Core Functions ---
    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function getInvariant() public view returns (uint256) {
        return invariant;
    }

    function swap(address sender, uint256 amountIn, bool zeroForOne) external onlyHook returns (uint256 amountOut) {
        if (amountIn == 0) revert LibErrors.ZeroAmount();
        if (totalLiquidity == 0) revert LibErrors.InsufficientLiquidity();

        // Calculate output using oracle-anchored invariant
        if (zeroForOne) {
            amountOut = _getAmountOut(amountIn, reserve0, reserve1, true);
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            amountOut = _getAmountOut(amountIn, reserve1, reserve0, false);
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }

        // Update invariant
        _updateInvariant();

        emit Swap(sender, amountIn, amountOut);
        emit ReservesUpdated(reserve0, reserve1);
    }

    function updateOraclePrice(uint256 newPrice) external onlyHook {
        if (newPrice == 0) revert LibErrors.InvalidParameter();
        
        oraclePrice = newPrice;
        
        // Recalculate invariant with new oracle price
        _updateInvariant();
        
        emit OraclePriceUpdated(newPrice);
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external onlyHook returns (uint256 liquidity) {
        if (amount0 == 0 && amount1 == 0) revert LibErrors.ZeroAmount();

        if (totalLiquidity == 0) {
            // Initial liquidity
            liquidity = LibMath.sqrt(amount0 * amount1);
            reserve0 = amount0;
            reserve1 = amount1;
        } else {
            // Proportional liquidity addition
            uint256 liquidity0 = (amount0 * totalLiquidity) / reserve0;
            uint256 liquidity1 = (amount1 * totalLiquidity) / reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            
            reserve0 += amount0;
            reserve1 += amount1;
        }

        totalLiquidity += liquidity;
        _updateInvariant();
        
        emit ReservesUpdated(reserve0, reserve1);
    }

    function removeLiquidity(uint256 liquidity) external onlyHook returns (uint256 amount0, uint256 amount1) {
        if (liquidity == 0) revert LibErrors.ZeroAmount();
        if (liquidity > totalLiquidity) revert LibErrors.InsufficientLiquidity();

        amount0 = (liquidity * reserve0) / totalLiquidity;
        amount1 = (liquidity * reserve1) / totalLiquidity;

        reserve0 -= amount0;
        reserve1 -= amount1;
        totalLiquidity -= liquidity;

        _updateInvariant();
        emit ReservesUpdated(reserve0, reserve1);
    }

    // --- Internal Functions ---
    
    /// @notice Calculate swap output using oracle-anchored invariant
    /// @dev Uses fixed constants D=88, A=300 from LibMath
    function _getAmountOut(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut, 
        bool isZeroForOne
    ) internal view returns (uint256 amountOut) {
        // Determine oracle price direction
        // For zeroForOne: swapping token0 for token1, price = token1/token0
        // For oneForZero: swapping token1 for token0, price = token0/token1 = 1/oraclePrice
        uint256 effectiveOraclePrice = isZeroForOne ? oraclePrice : LibMath.wdiv(LibMath.WAD, oraclePrice);
        
        // Use the corrected swap calculation from LibMath with fixed constants
        amountOut = LibMath.calculateSwapOutput(
            amountIn,
            reserveIn,
            reserveOut,
            effectiveOraclePrice,
            A
        );
        
        // Apply minimum output check (slippage protection)
        if (amountOut == 0) revert LibErrors.InvalidSwapAmount();
    }

    /// @notice Update the oracle-anchored invariant
    function _updateInvariant() internal {
        if (reserve0 == 0 || reserve1 == 0) {
            invariant = 0;
            return;
        }

        // Calculate invariant using oracle price and amplification factor
        invariant = LibMath.calculateInvariant(reserve0, reserve1, oraclePrice, A);
        
        emit InvariantUpdated(invariant);
    }

    // --- View Functions ---
    function getAmountOut(uint256 amountIn, bool zeroForOne) external view returns (uint256) {
        if (amountIn == 0) return 0;
        if (zeroForOne) {
            return _getAmountOut(amountIn, reserve0, reserve1, true);
        } else {
            return _getAmountOut(amountIn, reserve1, reserve0, false);
        }
    }

    function getPoolInfo() external view returns (
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _invariant,
        uint256 _oraclePrice,
        uint256 _totalLiquidity
    ) {
        return (reserve0, reserve1, invariant, oraclePrice, totalLiquidity);
    }
} 