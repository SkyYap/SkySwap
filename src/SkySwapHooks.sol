// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {IPoolManager, SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {LibErrors} from "./libraries/LibErrors.sol";
import {LibTypes} from "./libraries/LibTypes.sol";
import {LibMath} from "./libraries/LibMath.sol";
import {SkyUSDVault} from "./SkyUSDVault.sol";
import {CollateralManager} from "./CollateralManager.sol";
import {OracleManager} from "./OracleManager.sol";
import {SkySwapPool} from "./SkySwapPool.sol";

/// @title SkySwapHooks
/// @notice Uniswap v4-compliant hook logic for SkySwap (see .cursor/rules/uniswap-v4-hooks.md)
contract SkySwapHooks is BaseHook {
    using PoolIdLibrary for PoolKey;

    // --- State ---
    address public owner;
    SkyUSDVault public immutable skyUSDVault;
    CollateralManager public immutable collateralManager;
    OracleManager public immutable oracleManager;
    
    // Pool-specific state tracking
    mapping(PoolId => address) public poolContracts;
    mapping(PoolId => LibTypes.PoolState) public poolStates;
    mapping(address => mapping(PoolId => LibTypes.UserPosition)) public userPositions;

    // --- Events ---
    event PoolInitialized(PoolId indexed poolId, address poolContract);
    event SingleSidedLiquidityAdded(address indexed user, PoolId indexed poolId, uint256 amount);
    event CollateralLoopCompleted(address indexed user, PoolId indexed poolId);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    constructor(
        IPoolManager _poolManager,
        address _skyUSDVault,
        address _collateralManager,
        address _oracleManager
    ) BaseHook(_poolManager) {
        owner = msg.sender;
        skyUSDVault = SkyUSDVault(_skyUSDVault);
        collateralManager = CollateralManager(_collateralManager);
        oracleManager = OracleManager(payable(_oracleManager));
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // --- Admin Functions ---
    function setPoolContract(PoolId poolId, address poolContract) external onlyOwner {
        if (poolContract == address(0)) revert LibErrors.ZeroAddress();
        poolContracts[poolId] = poolContract;
        emit PoolInitialized(poolId, poolContract);
    }

    // --- Hook Entry Points ---

    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Validate oracle prices
        _validateOraclePrices(key);
        
        // Handle single-sided liquidity via flash mint
        if (hookData.length > 0) {
            _handleSingleSidedLiquidity(sender, poolId, params, hookData);
        }
        
        return this.beforeAddLiquidity.selector;
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        
        // Update user position tracking
        _updateUserPosition(sender, poolId, params);
        
        // Complete collateral loop if single-sided
        if (hookData.length > 0) {
            _completeCollateralLoop(sender, poolId);
        }
        
        return (this.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Check if user has sufficient collateral for withdrawal
        _validateLiquidityRemoval(sender, poolId, params);
        
        return this.beforeRemoveLiquidity.selector;
    }

    function _afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta0,
        BalanceDelta delta1,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        
        // Handle debt repayment and collateral release
        _handleLiquidityRemoval(sender, poolId, params);
        
        return (this.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // Validate oracle prices and peg bands
        _validateOraclePrices(key);
        
        // Calculate dynamic fee based on deviation from peg
        uint24 dynamicFee = _calculateDynamicFee(key, params);
        
        return (this.beforeSwap.selector, BeforeSwapDelta.wrap(0), dynamicFee);
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        
        // Update pool state and check for rebalancing needs
        _updatePoolState(poolId, key);
        
        return (this.afterSwap.selector, 0);
    }

    // --- Internal Helper Functions ---
    
    function _validateOraclePrices(PoolKey calldata key) internal view {
        // Get oracle prices for both tokens
        try oracleManager.getPrice(Currency.unwrap(key.currency0)) returns (uint256 price0) {
            // Check if price is within acceptable bounds
            if (price0 == 0) revert LibErrors.InvalidOracle();
        } catch {
            // Check if it's a data stream that needs updating
            if (oracleManager.isDataStreamActive(Currency.unwrap(key.currency0))) {
                revert LibErrors.StalePrice(); // Data stream needs fresh report
            }
            revert LibErrors.OracleNotSet();
        }

        try oracleManager.getPrice(Currency.unwrap(key.currency1)) returns (uint256 price1) {
            if (price1 == 0) revert LibErrors.InvalidOracle();
        } catch {
            // Check if it's a data stream that needs updating
            if (oracleManager.isDataStreamActive(Currency.unwrap(key.currency1))) {
                revert LibErrors.StalePrice(); // Data stream needs fresh report
            }
            revert LibErrors.OracleNotSet();
        }
    }

    function _validateOraclePricesWithReports(
        PoolKey calldata key,
        bytes calldata signedReport0,
        bytes calldata signedReport1
    ) internal returns (uint256 price0, uint256 price1) {
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // Get price for token0
        if (oracleManager.isDataStreamActive(token0) && signedReport0.length > 0) {
            price0 = oracleManager.getPriceWithReport{value: msg.value / 2}(token0, signedReport0);
        } else {
            price0 = oracleManager.getPrice(token0);
        }

        // Get price for token1
        if (oracleManager.isDataStreamActive(token1) && signedReport1.length > 0) {
            price1 = oracleManager.getPriceWithReport{value: msg.value - msg.value / 2}(token1, signedReport1);
        } else {
            price1 = oracleManager.getPrice(token1);
        }

        if (price0 == 0 || price1 == 0) revert LibErrors.InvalidOracle();
    }
    
    function _handleSingleSidedLiquidity(
        address sender,
        PoolId poolId,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal {
        // Decode hook data to determine which token user is providing
        (address tokenIn, uint256 amountIn) = abi.decode(hookData, (address, uint256));
        
        if (amountIn == 0) revert LibErrors.ZeroAmount();
        
        // Flash mint skyUSD equal to the token value
        uint256 oraclePrice = oracleManager.getPrice(tokenIn);
        uint256 skyUSDAmount = LibMath.wmul(amountIn, oraclePrice);
        
        // Flash mint skyUSD to this contract
        skyUSDVault.flashMint(address(this), skyUSDAmount);
        
        // Store flash loan info for later repayment
        userPositions[sender][poolId].debt = skyUSDAmount;
        
        emit SingleSidedLiquidityAdded(sender, poolId, amountIn);
    }
    
    function _updateUserPosition(
        address sender,
        PoolId poolId,
        ModifyLiquidityParams calldata params
    ) internal {
        userPositions[sender][poolId].lpCollateral += uint256(params.liquidityDelta);
        userPositions[sender][poolId].lastUpdate = block.timestamp;
    }
    
    function _completeCollateralLoop(address sender, PoolId poolId) internal {
        uint256 flashLoanAmount = userPositions[sender][poolId].debt;
        uint256 lpTokenAmount = userPositions[sender][poolId].lpCollateral;
        
        // Step 1: Deposit LP tokens as collateral
        collateralManager.depositCollateral(sender, lpTokenAmount);
        
        // Step 2: Borrow skyUSD against LP collateral (50% LTV)
        uint256 borrowAmount = flashLoanAmount; // Should equal flash loan amount
        skyUSDVault.mint(address(this), borrowAmount);
        
        // Step 3: Update user debt in collateral manager
        collateralManager.updateUserDebt(sender, borrowAmount);
        
        // Step 4: Repay flash loan
        skyUSDVault.burn(address(this), flashLoanAmount);
        
        // Step 5: Clear temporary debt tracking
        userPositions[sender][poolId].debt = borrowAmount; // Now tracks actual debt
        
        emit CollateralLoopCompleted(sender, poolId);
    }
    
    function _validateLiquidityRemoval(
        address sender,
        PoolId poolId,
        ModifyLiquidityParams calldata params
    ) internal view {
        uint256 removalAmount = uint256(-params.liquidityDelta);
        uint256 currentCollateral = userPositions[sender][poolId].lpCollateral;
        
        if (removalAmount > currentCollateral) revert LibErrors.InsufficientCollateral();
        
        // Check if remaining collateral would maintain safe LTV
        uint256 remainingCollateral = currentCollateral - removalAmount;
        uint256 userDebt = userPositions[sender][poolId].debt;
        
        if (userDebt > 0) {
            uint256 newLTV = LibMath.calculateLTV(userDebt, remainingCollateral);
            if (newLTV > collateralManager.LTV_RATIO()) revert LibErrors.LTVTooHigh();
        }
    }
    
    function _handleLiquidityRemoval(
        address sender,
        PoolId poolId,
        ModifyLiquidityParams calldata params
    ) internal {
        uint256 removalAmount = uint256(-params.liquidityDelta);
        uint256 userDebt = userPositions[sender][poolId].debt;
        
        if (userDebt > 0) {
            // Proportional debt repayment
            uint256 debtToRepay = LibMath.wmul(userDebt, 
                LibMath.wdiv(removalAmount, userPositions[sender][poolId].lpCollateral));
            
            // Burn skyUSD to repay debt
            skyUSDVault.burn(sender, debtToRepay);
            skyUSDVault.repay(sender, debtToRepay);
            
            // Update debt tracking
            userPositions[sender][poolId].debt -= debtToRepay;
            collateralManager.updateUserDebt(sender, userPositions[sender][poolId].debt);
        }
        
        // Withdraw collateral
        collateralManager.withdrawCollateral(sender, removalAmount);
        userPositions[sender][poolId].lpCollateral -= removalAmount;
    }
    
    function _calculateDynamicFee(
        PoolKey calldata key,
        SwapParams calldata params
    ) internal view returns (uint24) {
        // Get current pool price and oracle price
        address tokenIn = params.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
        address tokenOut = params.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);
        
        uint256 oraclePriceIn = oracleManager.getPrice(tokenIn);
        uint256 oraclePriceOut = oracleManager.getPrice(tokenOut);
        uint256 oracleRatio = LibMath.wdiv(oraclePriceIn, oraclePriceOut);
        
        // Check if swap is within peg band
        bool withinPegBand = oracleManager.isWithinPegBand(tokenIn, oraclePriceIn) && 
                            oracleManager.isWithinPegBand(tokenOut, oraclePriceOut);
        
        if (withinPegBand) {
            return 500; // 0.05% fee for swaps within peg
        } else {
            return 3000; // 0.3% fee for swaps outside peg
        }
    }
    
    function _updatePoolState(PoolId poolId, PoolKey calldata key) internal {
        // Update pool reserves and invariant
        address poolContract = poolContracts[poolId];
        if (poolContract != address(0)) {
            SkySwapPool pool = SkySwapPool(poolContract);
            (uint256 reserve0, uint256 reserve1) = pool.getReserves();
            
            poolStates[poolId].reserve0 = reserve0;
            poolStates[poolId].reserve1 = reserve1;
            poolStates[poolId].invariant = pool.getInvariant();
            
            // Update oracle price in pool
            uint256 oraclePrice = oracleManager.getPrice(Currency.unwrap(key.currency0));
            pool.updateOraclePrice(oraclePrice);
            poolStates[poolId].oraclePrice = oraclePrice;
        }
    }
}