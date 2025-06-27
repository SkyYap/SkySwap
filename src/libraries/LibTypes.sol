// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title LibTypes
/// @notice Shared types and structs for SkySwap protocol
library LibTypes {
    struct UserPosition {
        uint256 lpCollateral;
        uint256 debt;
        uint256 lastUpdate;
    }

    struct PoolState {
        uint256 reserve0;
        uint256 reserve1;
        uint256 invariant;
        uint256 oraclePrice;
        uint256 totalLiquidity;
    }

    struct OracleData {
        uint256 price;
        uint256 lastUpdate;
        uint256 pegBand; // basis points
    }

    struct DataStreamConfig {
        bytes32 feedId;
        uint8 decimals;
        bool isActive;
    }

    struct FlashLoanParams {
        address recipient;
        uint256 amount;
        bytes data;
    }

    struct SwapParams {
        uint256 amountIn;
        uint256 minAmountOut;
        bool zeroForOne;
        address to;
    }
} 