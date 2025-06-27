// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SkySwapPool} from "../src/SkySwapPool.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";

contract SkySwapPoolTest is Test {
    SkySwapPool pool;
    address hook;
    address alice;
    uint256 constant INITIAL_ORACLE_PRICE = 1e18; // 1:1 price

    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);
    event InvariantUpdated(uint256 newInvariant);
    event OraclePriceUpdated(uint256 newOraclePrice);
    event ReservesUpdated(uint256 reserve0, uint256 reserve1);

    function setUp() public {
        pool = new SkySwapPool(INITIAL_ORACLE_PRICE);
        hook = makeAddr("hook");
        alice = makeAddr("alice");
        
        // Set the hook
        pool.setSkySwapHooks(hook);
    }

    function testInitialState() public {
        assertEq(pool.owner(), address(this));
        assertEq(pool.A(), 300);
        assertEq(pool.totalLiquidity(), 0);
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, 0);
        assertEq(reserve1, 0);
    }

    function testSetSkySwapHooks() public {
        address newHook = makeAddr("newHook");
        pool.setSkySwapHooks(newHook);
        
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        pool.setSkySwapHooks(address(0));
    }

    function testSetSkySwapHooks_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.OnlyOwner.selector);
        pool.setSkySwapHooks(makeAddr("newHook"));
    }

    function testAddLiquidity_Initial() public {
        uint256 amount0 = 1000e18;
        uint256 amount1 = 1000e18;
        
        vm.prank(hook);
        uint256 liquidity = pool.addLiquidity(amount0, amount1);
        
        assertTrue(liquidity > 0);
        assertEq(pool.totalLiquidity(), liquidity);
        
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, amount0);
        assertEq(reserve1, amount1);
    }

    function testAddLiquidity_ZeroAmount() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAmount.selector);
        pool.addLiquidity(0, 0);
    }

    function testAddLiquidity_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        pool.addLiquidity(1000e18, 1000e18);
    }

    function testAddLiquidity_Proportional() public {
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(1000e18, 1000e18);
        
        // Add proportional liquidity
        vm.prank(hook);
        uint256 liquidity2 = pool.addLiquidity(500e18, 500e18);
        
        assertTrue(liquidity2 > 0);
        
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, 1500e18);
        assertEq(reserve1, 1500e18);
    }

    function testRemoveLiquidity() public {
        uint256 initialAmount = 1000e18;
        
        // Add initial liquidity
        vm.prank(hook);
        uint256 liquidity = pool.addLiquidity(initialAmount, initialAmount);
        
        // Remove half the liquidity
        uint256 removeAmount = liquidity / 2;
        
        vm.prank(hook);
        (uint256 amount0, uint256 amount1) = pool.removeLiquidity(removeAmount);
        
        assertTrue(amount0 > 0);
        assertTrue(amount1 > 0);
        assertEq(pool.totalLiquidity(), liquidity - removeAmount);
        
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, initialAmount - amount0);
        assertEq(reserve1, initialAmount - amount1);
    }

    function testRemoveLiquidity_ZeroAmount() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAmount.selector);
        pool.removeLiquidity(0);
    }

    function testRemoveLiquidity_InsufficientLiquidity() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InsufficientLiquidity.selector);
        pool.removeLiquidity(1000e18);
    }

    function testSwap() public {
        uint256 liquidityAmount = 10000e18;
        uint256 swapAmount = 100e18;
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        vm.expectEmit(true, false, false, false);
        emit Swap(alice, swapAmount, 0); // amountOut will be calculated
        
        vm.prank(hook);
        uint256 amountOut = pool.swap(alice, swapAmount, true); // zeroForOne
        
        assertTrue(amountOut > 0);
        assertTrue(amountOut < swapAmount); // Should be less due to slippage
        
        (uint256 reserve0, uint256 reserve1) = pool.getReserves();
        assertEq(reserve0, liquidityAmount + swapAmount);
        assertEq(reserve1, liquidityAmount - amountOut);
    }

    function testSwap_ZeroAmount() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAmount.selector);
        pool.swap(alice, 0, true);
    }

    function testSwap_InsufficientLiquidity() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InsufficientLiquidity.selector);
        pool.swap(alice, 1000e18, true);
    }

    function testSwap_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        pool.swap(alice, 1000e18, true);
    }

    function testSwap_BothDirections() public {
        uint256 liquidityAmount = 10000e18;
        uint256 swapAmount = 100e18;
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        // Swap token0 for token1
        vm.prank(hook);
        uint256 amountOut1 = pool.swap(alice, swapAmount, true);
        
        // Swap token1 for token0
        vm.prank(hook);
        uint256 amountOut2 = pool.swap(alice, swapAmount, false);
        
        assertTrue(amountOut1 > 0);
        assertTrue(amountOut2 > 0);
    }

    function testUpdateOraclePrice() public {
        uint256 newPrice = 2e18; // 2:1 price
        
        vm.expectEmit(false, false, false, true);
        emit OraclePriceUpdated(newPrice);
        
        vm.prank(hook);
        pool.updateOraclePrice(newPrice);
        
        (,,, uint256 oraclePrice,) = pool.getPoolInfo();
        assertEq(oraclePrice, newPrice);
    }

    function testUpdateOraclePrice_ZeroPrice() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InvalidParameter.selector);
        pool.updateOraclePrice(0);
    }

    function testUpdateOraclePrice_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        pool.updateOraclePrice(2e18);
    }

    function testGetAmountOut() public {
        uint256 liquidityAmount = 10000e18;
        uint256 swapAmount = 100e18;
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        // Get quote for swap
        uint256 amountOut = pool.getAmountOut(swapAmount, true);
        assertTrue(amountOut > 0);
        
        // Actual swap should match quote
        vm.prank(hook);
        uint256 actualAmountOut = pool.swap(alice, swapAmount, true);
        assertEq(amountOut, actualAmountOut);
    }

    function testGetAmountOut_ZeroAmount() public {
        uint256 amountOut = pool.getAmountOut(0, true);
        assertEq(amountOut, 0);
    }

    function testGetPoolInfo() public {
        uint256 liquidityAmount = 1000e18;
        
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        (uint256 reserve0, uint256 reserve1, uint256 invariant, uint256 oraclePrice, uint256 totalLiquidity) = pool.getPoolInfo();
        
        assertEq(reserve0, liquidityAmount);
        assertEq(reserve1, liquidityAmount);
        assertEq(oraclePrice, INITIAL_ORACLE_PRICE);
        assertEq(totalLiquidity, pool.totalLiquidity());
        assertTrue(invariant > 0);
    }

    function testInvariantUpdatesOnSwap() public {
        uint256 liquidityAmount = 10000e18;
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        uint256 initialInvariant = pool.getInvariant();
        
        // Perform swap
        vm.prank(hook);
        pool.swap(alice, 100e18, true);
        
        uint256 newInvariant = pool.getInvariant();
        // Invariant should change due to oracle anchoring
        assertNotEq(initialInvariant, newInvariant);
    }

    function testOraclePriceImpactOnSwap() public {
        uint256 liquidityAmount = 10000e18;
        uint256 swapAmount = 100e18;
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        // Get quote with current oracle price
        uint256 amountOut1 = pool.getAmountOut(swapAmount, true);
        
        // Update oracle price
        vm.prank(hook);
        pool.updateOraclePrice(2e18);
        
        // Get quote with new oracle price
        uint256 amountOut2 = pool.getAmountOut(swapAmount, true);
        
        // Quotes should be different due to oracle price change
        assertNotEq(amountOut1, amountOut2);
    }

    function testFuzz_AddRemoveLiquidity(uint256 amount0, uint256 amount1) public {
        vm.assume(amount0 > 0 && amount0 < type(uint128).max);
        vm.assume(amount1 > 0 && amount1 < type(uint128).max);
        
        vm.prank(hook);
        uint256 liquidity = pool.addLiquidity(amount0, amount1);
        
        assertTrue(liquidity > 0);
        assertEq(pool.totalLiquidity(), liquidity);
        
        vm.prank(hook);
        (uint256 returnAmount0, uint256 returnAmount1) = pool.removeLiquidity(liquidity);
        
        assertEq(returnAmount0, amount0);
        assertEq(returnAmount1, amount1);
        assertEq(pool.totalLiquidity(), 0);
    }

    function testFuzz_Swap(uint256 liquidityAmount, uint256 swapAmount, bool zeroForOne) public {
        vm.assume(liquidityAmount > 1e18 && liquidityAmount < type(uint128).max);
        vm.assume(swapAmount > 0 && swapAmount < liquidityAmount / 2);
        
        // Add initial liquidity
        vm.prank(hook);
        pool.addLiquidity(liquidityAmount, liquidityAmount);
        
        // Perform swap
        vm.prank(hook);
        uint256 amountOut = pool.swap(alice, swapAmount, zeroForOne);
        
        assertTrue(amountOut > 0);
        assertTrue(amountOut < swapAmount); // Should have some slippage
    }
} 