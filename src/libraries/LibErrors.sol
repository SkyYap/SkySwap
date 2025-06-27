// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title LibErrors
/// @notice Custom errors for SkySwap protocol
library LibErrors {
    // --- Access Control ---
    error Unauthorized();
    error OnlyOwner();
    error OnlyHook();
    error OnlyVault();

    // --- Oracle ---
    error OracleNotSet();
    error StalePrice();
    error PriceOutOfBounds();
    error InvalidOracle();

    // --- Data Streams ---
    error DataStreamNotConfigured();
    error InsufficientFee();
    error InvalidFeedId();
    error ReportExpired();
    error InvalidPrice();

    // --- Collateral ---
    error InsufficientCollateral();
    error LTVTooHigh();
    error NotLiquidatable();
    error CollateralLocked();

    // --- Vault ---
    error InsufficientBalance();
    error FlashLoanNotRepaid();
    error InvalidFlashLoanCallback();
    error DebtExceedsLimit();

    // --- Pool ---
    error InsufficientLiquidity();
    error InvalidSwapAmount();
    error SlippageExceeded();
    error PoolNotInitialized();

    // --- Factory ---
    error PoolAlreadyExists();
    error InvalidHook();
    error InvalidTokenPair();

    // --- General ---
    error ZeroAddress();
    error ZeroAmount();
    error InvalidParameter();
} 