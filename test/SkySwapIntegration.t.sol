// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SkySwapFactory} from "../src/SkySwapFactory.sol";
import {SkySwapHooks} from "../src/SkySwapHooks.sol";
import {SkySwapPool} from "../src/SkySwapPool.sol";
import {USYCVault} from "../src/USYCVault.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

// Mock IPoolManager for testing
contract MockPoolManager {
    // Minimal implementation for testing hooks
    function currencyDelta(address, Currency) external pure returns (int256) {
        return 0;
    }
}

// Mock Chainlink oracle
contract MockAggregatorV3 {
    int256 public price;
    uint8 public decimals;
    uint256 public updatedAt;

    constructor(int256 _price, uint8 _decimals) {
        price = _price;
        decimals = _decimals;
        updatedAt = block.timestamp;
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 _updatedAt,
        uint80 answeredInRound
    ) {
        return (1, price, block.timestamp, updatedAt, 1);
    }

    function setPrice(int256 _price) external {
        price = _price;
        updatedAt = block.timestamp;
    }
}

contract SkySwapIntegrationTest is Test {
    // Core contracts
    SkySwapFactory factory;
    USYCVault usycVault;
    CollateralManager collateralManager;
    OracleManager oracleManager;
    SkySwapHooks hooks;
    SkySwapPool pool;
    
    // Mock tokens and oracles
    MockERC20 token0;
    MockERC20 token1;
    MockAggregatorV3 oracle0;
    MockAggregatorV3 oracle1;
    
    // Test accounts
    address alice;
    address bob;
    
    // Constants
    uint256 constant INITIAL_ORACLE_PRICE = 1e18;
    uint256 constant INITIAL_MINT = 1000000e18;

    function setUp() public {
        // Create test accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Deploy core contracts
        usycVault = new USYCVault();
        
        // Deploy mock verifier and link address for data streams
        address mockVerifier = makeAddr("verifier");
        address mockLink = makeAddr("link");
        oracleManager = new OracleManager(mockVerifier, mockLink);
        
        collateralManager = new CollateralManager(address(oracleManager));
        factory = new SkySwapFactory();
        
        // Deploy mock tokens
        token0 = new MockERC20("Token0", "TK0", 18);
        token1 = new MockERC20("Token1", "TK1", 18);
        
        // Ensure token0 < token1
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        
        // Deploy mock oracles
        oracle0 = new MockAggregatorV3(100e8, 8); // $100
        oracle1 = new MockAggregatorV3(200e8, 8); // $200
        
        // Set up Data Streams
        bytes32 feedId0 = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes32 feedId1 = 0x0000000000000000000000000000000000000000000000000000000000000002;
        
        oracleManager.configureDataStream(address(token0), feedId0, 8);
        oracleManager.configureDataStream(address(token1), feedId1, 8);
        oracleManager.setPegBand(address(token0), 500); // 5%
        oracleManager.setPegBand(address(token1), 500); // 5%
        
        // Deploy hooks (using a mock pool manager)
        MockPoolManager mockPoolManager = new MockPoolManager();
        hooks = new SkySwapHooks(
            IPoolManager(address(mockPoolManager)),
            address(usycVault),
            address(collateralManager),
            address(oracleManager)
        );
        
        // Set up contract relationships
        usycVault.setSkySwapHooks(address(hooks));
        collateralManager.setSkySwapHooks(address(hooks));
        
        // Deploy pool
        pool = new SkySwapPool(INITIAL_ORACLE_PRICE);
        pool.setSkySwapHooks(address(hooks));
        
        // Mint tokens to test accounts
        token0.mint(alice, INITIAL_MINT);
        token1.mint(alice, INITIAL_MINT);
        token0.mint(bob, INITIAL_MINT);
        token1.mint(bob, INITIAL_MINT);
        
        // Validate hooks in factory
        vm.etch(address(hooks), "0x1234567890"); // Add code for validation
        factory.setHookValidation(address(hooks), true);
    }

    function testFullIntegration_PoolCreation() public {
        // Create pool through factory
        address poolAddress = factory.createPool(
            address(token0),
            address(token1),
            address(hooks)
        );
        
        // Verify pool creation
        bytes32 poolId = factory.getPoolId(address(token0), address(token1), address(hooks));
        assertEq(factory.getPool(poolId), poolAddress);
        assertEq(factory.getHook(poolId), address(hooks));
    }

    function testFullIntegration_LiquidityAndSwap() public {
        uint256 liquidityAmount = 10000e18;
        uint256 swapAmount = 100e18;
        
        // Add liquidity to pool
        vm.prank(address(hooks));
        uint256 liquidity = pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        assertTrue(liquidity > 0);
        assertEq(pool.totalLiquidity(), liquidity);
        
        // Perform swap
        vm.prank(address(hooks));
        uint256 amountOut = pool.swap(alice, swapAmount, true);
        
        assertTrue(amountOut > 0);
        
        // Verify reserves updated
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, liquidityAmount + swapAmount);
        assertEq(reserve1, liquidityAmount - amountOut);
    }

    function testFullIntegration_CollateralAndDebt() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 400e18; // 40% LTV
        
        // Deposit collateral
        vm.prank(address(hooks));
        collateralManager.depositCollateral(alice, collateralAmount);
        
        // Mint USYC (creating debt)
        vm.prank(address(hooks));
        usycVault.mint(alice, debtAmount);
        
        // Update collateral manager with debt
        vm.prank(address(hooks));
        collateralManager.updateUserDebt(alice, debtAmount);
        
        // Verify states
        assertEq(usycVault.balanceOf(alice), debtAmount);
        assertEq(usycVault.getDebt(alice), debtAmount);
        assertEq(collateralManager.checkLTV(alice), 4000); // 40% in basis points
        assertFalse(collateralManager.isLiquidatable(alice));
    }

    function testFullIntegration_OraclePriceUpdates() public {
        uint256 liquidityAmount = 10000e18;
        
        // Add liquidity
        vm.prank(address(hooks));
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        // Get initial swap quote
        uint256 initialAmountOut = pool.getAmountOut(100e18, true);
        
        // Update oracle price via Data Stream (this would be done with signed reports in practice)
        // For testing, we'll simulate by directly updating cached price
        oracle0.setPrice(150e8); // $150
        
        // Update pool oracle price
        vm.prank(address(hooks));
        pool.updateOraclePrice(150e18);
        
        // Get new swap quote
        uint256 newAmountOut = pool.getAmountOut(100e18, true);
        
        // Quotes should be different
        assertNotEq(initialAmountOut, newAmountOut);
    }

    function testFullIntegration_FlashMint() public {
        uint256 flashAmount = 1000e18;
        
        // Create flash loan recipient
        MockFlashLoanRecipient recipient = new MockFlashLoanRecipient(usycVault);
        
        // Perform flash mint
        vm.prank(address(hooks));
        usycVault.flashMint(address(recipient), flashAmount);
        
        // Verify flash loan completed successfully
        assertEq(usycVault.balanceOf(address(recipient)), 0);
        assertEq(usycVault.totalSupply(), 0);
    }

    function testFullIntegration_Liquidation() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 400e18;
        
        // Setup position
        vm.prank(address(hooks));
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(address(hooks));
        usycVault.mint(alice, debtAmount);
        
        // Force liquidatable state by manipulating storage
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(alice, 0)),
            bytes32((block.timestamp << 128) | (600e18 << 64) | collateralAmount) // 60% LTV
        );
        
        assertTrue(collateralManager.isLiquidatable(alice));
        
        // Perform liquidation
        collateralManager.liquidate(alice);
        
        // Verify position cleared
        (uint256 lpCollateral, uint256 debt,) = collateralManager.userPositions(alice);
        assertEq(lpCollateral, 0);
        assertEq(debt, 0);
    }

    function testFullIntegration_PegBandValidation() public {
        // Test price within peg band
        assertTrue(oracleManager.isWithinPegBand(address(token0), 105e18)); // 5% above $100
        
        // Test price outside peg band
        assertFalse(oracleManager.isWithinPegBand(address(token0), 110e18)); // 10% above $100
        
        // Update peg band
        oracleManager.setPegBand(address(token0), 1000); // 10%
        
        // Now 10% should be within band
        assertTrue(oracleManager.isWithinPegBand(address(token0), 110e18));
    }

    function testFullIntegration_MultipleUsers() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 300e18; // 30% LTV
        
        // Alice deposits collateral and mints USYC
        vm.prank(address(hooks));
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(address(hooks));
        usycVault.mint(alice, debtAmount);
        
        vm.prank(address(hooks));
        collateralManager.updateUserDebt(alice, debtAmount);
        
        // Bob deposits collateral and mints USYC
        vm.prank(address(hooks));
        collateralManager.depositCollateral(bob, collateralAmount);
        
        vm.prank(address(hooks));
        usycVault.mint(bob, debtAmount);
        
        vm.prank(address(hooks));
        collateralManager.updateUserDebt(bob, debtAmount);
        
        // Verify both users have correct states
        assertEq(usycVault.balanceOf(alice), debtAmount);
        assertEq(usycVault.balanceOf(bob), debtAmount);
        assertEq(usycVault.totalSupply(), debtAmount * 2);
        
        assertEq(collateralManager.checkLTV(alice), 3000); // 30%
        assertEq(collateralManager.checkLTV(bob), 3000); // 30%
        
        // Alice transfers USYC to Bob
        vm.prank(alice);
        usycVault.transfer(bob, debtAmount / 2);
        
        assertEq(usycVault.balanceOf(alice), debtAmount / 2);
        assertEq(usycVault.balanceOf(bob), debtAmount + debtAmount / 2);
    }

    function testFullIntegration_ErrorHandling() public {
        // Test data stream not configured error
        MockERC20 unknownToken = new MockERC20("Unknown", "UNK", 18);
        
        vm.expectRevert(LibErrors.DataStreamNotConfigured.selector);
        oracleManager.getPrice(address(unknownToken));
        
        // Test insufficient collateral error
        vm.prank(address(hooks));
        vm.expectRevert(LibErrors.InsufficientCollateral.selector);
        collateralManager.withdrawCollateral(alice, 1000e18);
        
        // Test hook-only functions
        vm.expectRevert(LibErrors.OnlyHook.selector);
        usycVault.mint(alice, 1000e18);
        
        vm.expectRevert(LibErrors.OnlyHook.selector);
        collateralManager.depositCollateral(alice, 1000e18);
        
        vm.expectRevert(LibErrors.OnlyHook.selector);
        pool.swap(alice, 1000e18, true);
    }
}

// Mock contract for flash loan testing
contract MockFlashLoanRecipient {
    USYCVault public vault;
    
    constructor(USYCVault _vault) {
        vault = _vault;
    }
    
    function onFlashLoan(uint256 amount) external {
        vault.approve(address(vault), amount);
    }
}

