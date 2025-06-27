// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./libraries/LibErrors.sol";
import {LibTypes} from "./libraries/LibTypes.sol";
import {LibMath} from "./libraries/LibMath.sol";

/// @title CollateralManager
/// @notice Tracks LP collateral, enforces 50% LTV, and handles liquidation (see .cursor/rules/uniswap-v4-hooks.md)
contract CollateralManager {
    // --- State ---
    address public owner;
    address public skySwapHooks;
    address public oracleManager;
    
    mapping(address => LibTypes.UserPosition) public userPositions;
    uint256 public constant LTV_RATIO = 5000; // 50% LTV in basis points

    // --- Events ---
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event DebtUpdated(address indexed user, uint256 newDebt);
    event Liquidated(address indexed user, uint256 collateralSeized);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    modifier onlyHook() {
        if (msg.sender != skySwapHooks) revert LibErrors.OnlyHook();
        _;
    }

    constructor(address _oracleManager) {
        owner = msg.sender;
        oracleManager = _oracleManager;
    }

    // --- Admin Functions ---
    function setSkySwapHooks(address _skySwapHooks) external onlyOwner {
        if (_skySwapHooks == address(0)) revert LibErrors.ZeroAddress();
        skySwapHooks = _skySwapHooks;
    }

    // --- Core Functions ---
    function depositCollateral(address user, uint256 amount) external onlyHook {
        if (user == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();

        userPositions[user].lpCollateral += amount;
        userPositions[user].lastUpdate = block.timestamp;

        emit CollateralDeposited(user, amount);
    }

    function withdrawCollateral(address user, uint256 amount) external onlyHook {
        if (user == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();
        if (userPositions[user].lpCollateral < amount) revert LibErrors.InsufficientCollateral();

        userPositions[user].lpCollateral -= amount;
        userPositions[user].lastUpdate = block.timestamp;

        // Check LTV after withdrawal
        uint256 ltv = checkLTV(user);
        if (ltv > LTV_RATIO) revert LibErrors.LTVTooHigh();

        emit CollateralWithdrawn(user, amount);
    }

    function updateUserDebt(address user, uint256 newDebt) external onlyHook {
        if (user == address(0)) revert LibErrors.ZeroAddress();

        userPositions[user].debt = newDebt;
        userPositions[user].lastUpdate = block.timestamp;

        // Check LTV after debt update
        uint256 ltv = checkLTV(user);
        if (ltv > LTV_RATIO) revert LibErrors.LTVTooHigh();

        emit DebtUpdated(user, newDebt);
    }

    function getCollateralValue(address user) public view returns (uint256 value) {
        // TODO: Integrate with oracle to get LP token value
        // For now, assume 1:1 ratio (to be implemented with oracle integration)
        value = userPositions[user].lpCollateral;
    }

    function checkLTV(address user) public view returns (uint256 ltv) {
        uint256 debt = userPositions[user].debt;
        uint256 collateralValue = getCollateralValue(user);
        ltv = LibMath.calculateLTV(debt, collateralValue);
    }

    function isLiquidatable(address user) public view returns (bool) {
        return checkLTV(user) > LTV_RATIO;
    }

    function liquidate(address user) external {
        if (!isLiquidatable(user)) revert LibErrors.NotLiquidatable();

        uint256 collateralToSeize = userPositions[user].lpCollateral;
        uint256 debtToRepay = userPositions[user].debt;

        // Clear user position
        delete userPositions[user];

        // TODO: Transfer collateral to liquidator and handle debt repayment
        
        emit Liquidated(user, collateralToSeize);
    }
} 