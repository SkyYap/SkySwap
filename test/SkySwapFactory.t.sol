// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SkySwapFactory} from "../src/SkySwapFactory.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

contract SkySwapFactoryTest is Test {
    SkySwapFactory factory;
    MockERC20 token0;
    MockERC20 token1;
    address hook;
    address alice;
    address bob;

    function setUp() public {
        factory = new SkySwapFactory();
        
        // Deploy test tokens
        token0 = new MockERC20("Token0", "TK0", 18);
        token1 = new MockERC20("Token1", "TK1", 18);
        
        // Ensure token0 < token1 for consistent ordering
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        
        // Create mock hook address
        hook = makeAddr("hook");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Add some code to the hook address to pass validation
        vm.etch(hook, "0x1234567890");
    }

    function testInitialState() public {
        assertEq(factory.owner(), address(this));
        assertFalse(factory.validHooks(hook));
    }

    function testSetHookValidation() public {
        // Test setting hook validation as owner
        factory.setHookValidation(hook, true);
        assertTrue(factory.validHooks(hook));
        
        // Test event emission
        vm.expectEmit(true, false, false, true);
        emit SkySwapFactory.HookValidated(hook, false);
        factory.setHookValidation(hook, false);
        assertFalse(factory.validHooks(hook));
    }

    function testSetHookValidation_ZeroAddress() public {
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        factory.setHookValidation(address(0), true);
    }

    function testSetHookValidation_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.OnlyOwner.selector);
        factory.setHookValidation(hook, true);
    }

    function testCreatePool_Success() public {
        // First validate the hook
        factory.setHookValidation(hook, true);
        
        // Create pool
        bytes32 expectedPoolId = factory.generatePoolId(address(token0), address(token1), hook);
        
        vm.expectEmit(true, false, false, true);
        emit SkySwapFactory.PoolCreated(expectedPoolId, address(factory), hook);
        
        address poolAddress = factory.createPool(address(token0), address(token1), hook);
        
        // Verify pool was created
        assertEq(factory.getPool(expectedPoolId), poolAddress);
        assertEq(factory.getHook(expectedPoolId), hook);
    }

    function testCreatePool_WithoutHook() public {
        // Create pool without hook
        address poolAddress = factory.createPool(address(token0), address(token1), address(0));
        
        bytes32 poolId = factory.generatePoolId(address(token0), address(token1), address(0));
        assertEq(factory.getPool(poolId), poolAddress);
        assertEq(factory.getHook(poolId), address(0));
    }

    function testCreatePool_ZeroAddressToken() public {
        factory.setHookValidation(hook, true);
        
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        factory.createPool(address(0), address(token1), hook);
        
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        factory.createPool(address(token0), address(0), hook);
    }

    function testCreatePool_SameTokens() public {
        factory.setHookValidation(hook, true);
        
        vm.expectRevert(LibErrors.InvalidTokenPair.selector);
        factory.createPool(address(token0), address(token0), hook);
    }

    function testCreatePool_InvalidHook() public {
        // Try to create pool with unvalidated hook
        vm.expectRevert(LibErrors.InvalidHook.selector);
        factory.createPool(address(token0), address(token1), hook);
    }

    function testCreatePool_PoolAlreadyExists() public {
        factory.setHookValidation(hook, true);
        
        // Create pool first time
        factory.createPool(address(token0), address(token1), hook);
        
        // Try to create same pool again
        vm.expectRevert(LibErrors.PoolAlreadyExists.selector);
        factory.createPool(address(token0), address(token1), hook);
    }

    function testCreatePool_TokenOrdering() public {
        factory.setHookValidation(hook, true);
        
        // Create pool with reversed token order
        address poolAddress1 = factory.createPool(address(token1), address(token0), hook);
        
        // Pool ID should be the same regardless of input order
        bytes32 poolId = factory.generatePoolId(address(token0), address(token1), hook);
        assertEq(factory.getPool(poolId), poolAddress1);
    }

    function testGeneratePoolId() public {
        bytes32 poolId1 = factory.generatePoolId(address(token0), address(token1), hook);
        bytes32 poolId2 = factory.generatePoolId(address(token1), address(token0), hook);
        
        // Pool IDs should be different due to different order
        assertNotEq(poolId1, poolId2);
        
        // But getPoolId should handle ordering
        bytes32 orderedId1 = factory.getPoolId(address(token0), address(token1), hook);
        bytes32 orderedId2 = factory.getPoolId(address(token1), address(token0), hook);
        assertEq(orderedId1, orderedId2);
    }

    function testGetPoolId() public {
        bytes32 poolId = factory.getPoolId(address(token0), address(token1), hook);
        assertNotEq(poolId, bytes32(0));
        
        // Same pool ID for different input order
        bytes32 poolId2 = factory.getPoolId(address(token1), address(token0), hook);
        assertEq(poolId, poolId2);
    }

    function testHookValidation_NoCode() public {
        address emptyHook = makeAddr("emptyHook");
        factory.setHookValidation(emptyHook, true);
        
        // Should fail because hook has no code
        vm.expectRevert(LibErrors.InvalidHook.selector);
        factory.createPool(address(token0), address(token1), emptyHook);
    }

    function testFuzz_CreatePool(address _token0, address _token1, address _hook) public {
        // Skip zero addresses and same tokens
        vm.assume(_token0 != address(0) && _token1 != address(0));
        vm.assume(_token0 != _token1);
        vm.assume(_hook != address(0));
        
        // Add code to hook if it's not zero address
        vm.etch(_hook, "0x1234567890");
        factory.setHookValidation(_hook, true);
        
        address poolAddress = factory.createPool(_token0, _token1, _hook);
        assertNotEq(poolAddress, address(0));
        
        bytes32 poolId = factory.getPoolId(_token0, _token1, _hook);
        assertEq(factory.getPool(poolId), poolAddress);
        assertEq(factory.getHook(poolId), _hook);
    }
} 