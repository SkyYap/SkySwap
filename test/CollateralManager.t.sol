// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";
import {LibTypes} from "../src/libraries/LibTypes.sol";

contract CollateralManagerTest is Test {
    CollateralManager collateralManager;
    OracleManager oracleManager;
    address hook;
    address alice;
    address bob;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event DebtUpdated(address indexed user, uint256 newDebt);
    event Liquidated(address indexed user, uint256 collateralSeized);

    function setUp() public {
        // Deploy mock verifier and link address for data streams
        address mockVerifier = makeAddr("verifier");
        address mockLink = makeAddr("link");
        oracleManager = new OracleManager(mockVerifier, mockLink);
        
        collateralManager = new CollateralManager(address(oracleManager));
        
        hook = makeAddr("hook");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Set the hook
        collateralManager.setSkySwapHooks(hook);
    }

    function testInitialState() public {
        assertEq(collateralManager.owner(), address(this));
        assertEq(collateralManager.LTV_RATIO(), 5000); // 50%
        
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, 0);
        assertEq(position.debt, 0);
        assertEq(position.lastUpdate, 0);
    }

    function testSetSkySwapHooks() public {
        address newHook = makeAddr("newHook");
        collateralManager.setSkySwapHooks(newHook);
        
        // Should revert with zero address
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        collateralManager.setSkySwapHooks(address(0));
    }

    function testSetSkySwapHooks_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.OnlyOwner.selector);
        collateralManager.setSkySwapHooks(makeAddr("newHook"));
    }

    function testDepositCollateral() public {
        uint256 amount = 1000e18;
        
        vm.expectEmit(true, false, false, true);
        emit CollateralDeposited(alice, amount);
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, amount);
        
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, amount);
        assertEq(position.lastUpdate, block.timestamp);
    }

    function testDepositCollateral_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        collateralManager.depositCollateral(alice, 1000e18);
    }

    function testDepositCollateral_ZeroAddress() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        collateralManager.depositCollateral(address(0), 1000e18);
    }

    function testDepositCollateral_ZeroAmount() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAmount.selector);
        collateralManager.depositCollateral(alice, 0);
    }

    function testWithdrawCollateral() public {
        uint256 depositAmount = 1000e18;
        uint256 withdrawAmount = 300e18;
        
        // First deposit collateral
        vm.prank(hook);
        collateralManager.depositCollateral(alice, depositAmount);
        
        vm.expectEmit(true, false, false, true);
        emit CollateralWithdrawn(alice, withdrawAmount);
        
        vm.prank(hook);
        collateralManager.withdrawCollateral(alice, withdrawAmount);
        
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, depositAmount - withdrawAmount);
    }

    function testWithdrawCollateral_InsufficientCollateral() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InsufficientCollateral.selector);
        collateralManager.withdrawCollateral(alice, 1000e18);
    }

    function testWithdrawCollateral_LTVTooHigh() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 400e18; // 40% LTV
        
        // Setup: deposit collateral and create debt
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, debtAmount);
        
        // Try to withdraw too much collateral (would push LTV over 50%)
        uint256 withdrawAmount = 200e18; // Would leave 800e18 collateral with 400e18 debt = 50% LTV
        
        vm.prank(hook);
        collateralManager.withdrawCollateral(alice, withdrawAmount);
        
        // This should work since it's exactly 50%
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, collateralAmount - withdrawAmount);
        
        // But withdrawing more should fail
        vm.prank(hook);
        vm.expectRevert(LibErrors.LTVTooHigh.selector);
        collateralManager.withdrawCollateral(alice, 1);
    }

    function testUpdateUserDebt() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 400e18;
        
        // First deposit collateral
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.expectEmit(true, false, false, true);
        emit DebtUpdated(alice, debtAmount);
        
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, debtAmount);
        
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.debt, debtAmount);
    }

    function testUpdateUserDebt_LTVTooHigh() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 600e18; // 60% LTV - too high
        
        // First deposit collateral
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(hook);
        vm.expectRevert(LibErrors.LTVTooHigh.selector);
        collateralManager.updateUserDebt(alice, debtAmount);
    }

    function testGetCollateralValue() public {
        uint256 amount = 1000e18;
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, amount);
        
        // Currently returns 1:1 ratio
        uint256 value = collateralManager.getCollateralValue(alice);
        assertEq(value, amount);
    }

    function testCheckLTV() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 300e18;
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, debtAmount);
        
        uint256 ltv = collateralManager.checkLTV(alice);
        assertEq(ltv, 3000); // 30% in basis points
    }

    function testCheckLTV_NoCollateral() public {
        uint256 ltv = collateralManager.checkLTV(alice);
        assertEq(ltv, 0);
    }

    function testIsLiquidatable() public {
        uint256 collateralAmount = 1000e18;
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        // Safe LTV
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, 400e18);
        assertFalse(collateralManager.isLiquidatable(alice));
        
        // Exactly at limit
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, 500e18);
        assertFalse(collateralManager.isLiquidatable(alice));
        
        // Over limit
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, 501e18);
        assertTrue(collateralManager.isLiquidatable(alice));
    }

    function testLiquidate() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 600e18; // Over 50% LTV
        
        // Setup liquidatable position
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        // Force update debt to bypass LTV check (simulating external circumstances)
        vm.store(
            address(collateralManager),
            keccak256(abi.encode(alice, 0)), // userPositions[alice] slot
            bytes32((block.timestamp << 128) | (debtAmount << 64) | collateralAmount)
        );
        
        assertTrue(collateralManager.isLiquidatable(alice));
        
        vm.expectEmit(true, false, false, true);
        emit Liquidated(alice, collateralAmount);
        
        collateralManager.liquidate(alice);
        
        // Position should be cleared
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, 0);
        assertEq(position.debt, 0);
        assertEq(position.lastUpdate, 0);
    }

    function testLiquidate_NotLiquidatable() public {
        uint256 collateralAmount = 1000e18;
        uint256 debtAmount = 400e18; // Safe LTV
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateralAmount);
        
        vm.prank(hook);
        collateralManager.updateUserDebt(alice, debtAmount);
        
        vm.expectRevert(LibErrors.NotLiquidatable.selector);
        collateralManager.liquidate(alice);
    }

    function testFuzz_DepositWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount < type(uint128).max);
        vm.assume(withdrawAmount <= depositAmount);
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, depositAmount);
        
        vm.prank(hook);
        collateralManager.withdrawCollateral(alice, withdrawAmount);
        
        LibTypes.UserPosition memory position = getUserPosition(alice);
        assertEq(position.lpCollateral, depositAmount - withdrawAmount);
    }

    function testFuzz_LTVCalculation(uint256 collateral, uint256 debt) public {
        vm.assume(collateral > 0 && collateral < type(uint128).max);
        vm.assume(debt <= collateral && debt < type(uint128).max);
        
        vm.prank(hook);
        collateralManager.depositCollateral(alice, collateral);
        
        if (debt * 10000 / collateral <= 5000) {
            vm.prank(hook);
            collateralManager.updateUserDebt(alice, debt);
            
            uint256 ltv = collateralManager.checkLTV(alice);
            assertEq(ltv, debt * 10000 / collateral);
            assertFalse(collateralManager.isLiquidatable(alice));
        }
    }

    // Helper function to read userPositions mapping
    function getUserPosition(address user) internal view returns (LibTypes.UserPosition memory position) {
        (position.lpCollateral, position.debt, position.lastUpdate) = collateralManager.userPositions(user);
    }
} 