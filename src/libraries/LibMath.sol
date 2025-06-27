// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./LibErrors.sol";

/// @title LibMath
/// @notice Mathematical utilities for SkySwap protocol
library LibMath {
    uint256 constant WAD = 1e18; // 18 decimal precision (standard DeFi)
    uint256 constant RAY = 1e27; // 27 decimal precision (higher precision)
    uint256 constant BPS = 10000; // Basis points (100% = 10000)
    
    /// @notice Solve quadratic equation from SkySwap whitepaper: Lj*rj^2 - D*rj - A*Lj = 0
    /// @dev Used by pool math; A is fixed, D is supplied
    /// @param liquidity Total pool liquidity (Lj)
    /// @param D Fixed invariant constant
    /// @param A Fixed amplification constant
    /// @return newReserve New reserve amount after swap
    function solveQuadratic(uint256 liquidity, uint256 D, uint256 A) internal pure returns (uint256 newReserve) {
        if (liquidity == 0) revert LibErrors.InvalidParameter();
        
        // Calculate discriminant: D^2 + 4*A*Lj
        // With D=88, A=300: discriminant = 88^2 + 4*300*Lj = 7744 + 1200*Lj
        uint256 D_squared = D * D; // 88^2 = 7744
        uint256 fourALj = 4 * A * liquidity; // 4 * 300 * Lj = 1200 * Lj
        uint256 discriminant = D_squared + fourALj;
        uint256 sqrtDiscriminant = sqrt(discriminant);
        
        // rj = (D + sqrt(D^2 + 4*A*Lj)) / (2*Lj)
        // rj = (88 + sqrt(7744 + 1200*Lj)) / (2*Lj)
        newReserve = (D + sqrtDiscriminant) / (2 * liquidity);
    }

    /// @notice Calculate invariant using simplified oracle-anchored curve
    /// @param reserve0 Current asset balance of token0
    /// @param reserve1 Current asset balance of token1  
    /// @param oraclePrice Oracle price (token1/token0)
    /// @param A Amplification constant
    /// @return D Invariant value
    function calculateInvariant(
        uint256 reserve0,
        uint256 reserve1,
        uint256 oraclePrice,
        uint256 A
    ) internal pure returns (uint256 D) {
        // Guard against empty pools
        if (reserve0 == 0 || reserve1 == 0) return 0;
        
        // Simplified invariant calculation for oracle-anchored curve
        // D = reserve0 + reserve1 * oraclePrice + A * sqrt(reserve0 * reserve1)
        uint256 weightedReserve1 = wmul(reserve1, oraclePrice);
        uint256 product = sqrt(wmul(reserve0, reserve1));
        uint256 amplifiedProduct = wmul(A, product);
        
        D = reserve0 + weightedReserve1 + amplifiedProduct;
    }

    /// @notice Calculate swap output amount using oracle-anchored curve  
    /// @param amountIn Input amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @param oraclePrice Oracle price (output/input)
    /// @param A Amplification constant
    /// @return amountOut Output amount
    function calculateSwapOutput(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 oraclePrice,
        uint256 A
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0 || reserveIn == 0 || reserveOut == 0) return 0;

        // Calculate invariant before swap
        uint256 D = calculateInvariant(reserveIn, reserveOut, oraclePrice, A);
        
        // New input reserve after adding input amount
        uint256 newReserveIn = reserveIn + amountIn;
        
        // Calculate new output reserve that maintains invariant
        // Simplified calculation: use constant product with oracle adjustment
        uint256 k = wmul(reserveIn, wmul(reserveOut, oraclePrice));
        uint256 newReserveOut = wdiv(k, wmul(newReserveIn, oraclePrice));
        
        // Apply amplification factor for reduced slippage
        uint256 amplificationAdjustment = wdiv(WAD, A);
        newReserveOut = wmul(newReserveOut, WAD + amplificationAdjustment);
        
        if (newReserveOut >= reserveOut) return 0;
        amountOut = reserveOut - newReserveOut;
    }

    /// @notice Calculate LTV ratio
    /// @param debt User's debt amount
    /// @param collateralValue Value of user's collateral
    /// @return ltv LTV ratio in basis points (e.g., 5000 = 50%)
    function calculateLTV(uint256 debt, uint256 collateralValue) internal pure returns (uint256 ltv) {
        if (collateralValue == 0) return type(uint256).max;
        ltv = (debt * BPS) / collateralValue;
    }

    /// @notice Calculate price impact of a swap
    /// @param amountIn Input amount
    /// @param reserveIn Input reserve
    /// @param reserveOut Output reserve
    /// @return priceImpact Price impact in basis points
    function calculatePriceImpact(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 priceImpact) {
        if (reserveIn == 0 || reserveOut == 0) return 0;
        
        uint256 priceBeforeWAD = wdiv(reserveOut, reserveIn);
        uint256 newReserveIn = reserveIn + amountIn;
        uint256 priceAfterWAD = wdiv(reserveOut, newReserveIn);
        
        if (priceAfterWAD >= priceBeforeWAD) return 0;
        
        uint256 priceDiff = priceBeforeWAD - priceAfterWAD;
        priceImpact = (priceDiff * BPS) / priceBeforeWAD;
    }

    /// @notice Calculate slippage between expected and actual output
    /// @param expectedOutput Expected output amount
    /// @param actualOutput Actual output amount
    /// @return slippage Slippage in basis points
    function calculateSlippage(
        uint256 expectedOutput,
        uint256 actualOutput
    ) internal pure returns (uint256 slippage) {
        if (expectedOutput == 0) return 0;
        if (actualOutput >= expectedOutput) return 0;
        
        uint256 difference = expectedOutput - actualOutput;
        slippage = (difference * BPS) / expectedOutput;
    }

    /// @notice Square root function using Babylonian method
    /// @param x Input value
    /// @return z Square root of x
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 y = (x + 1) / 2;
        while (y < z) {
            z = y;
            y = (x / y + y) / 2;
        }
    }

    /// @notice Convert basis points to WAD (e.g., 500 bps = 0.05 WAD)
    /// @param bps Basis points
    /// @return wad WAD representation
    function bpsToWad(uint256 bps) internal pure returns (uint256 wad) {
        wad = (bps * WAD) / BPS;
    }

    /// @notice Convert WAD to basis points (e.g., 0.05 WAD = 500 bps)
    /// @param wad WAD value
    /// @return bps Basis points representation
    function wadToBps(uint256 wad) internal pure returns (uint256 bps) {
        bps = (wad * BPS) / WAD;
    }

    /// @notice Multiply two WAD values
    /// @param x First WAD value
    /// @param y Second WAD value
    /// @return z Product in WAD
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }

    /// @notice Divide two WAD values
    /// @param x Numerator in WAD
    /// @param y Denominator in WAD
    /// @return z Quotient in WAD
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) revert LibErrors.InvalidParameter();
        z = (x * WAD) / y;
    }

    /// @notice Calculate minimum of two values
    /// @param a First value
    /// @param b Second value
    /// @return Minimum value
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculate maximum of two values
    /// @param a First value
    /// @param b Second value
    /// @return Maximum value
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
} 