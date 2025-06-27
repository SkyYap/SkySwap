// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./libraries/LibErrors.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

/// @title SkySwapFactory
/// @notice Factory for deploying SkySwap pools and hooks (see .cursor/rules/uniswap-v4-hooks.md)
contract SkySwapFactory {
    // --- State ---
    address public owner;
    mapping(bytes32 => address) public pools; // poolId => pool address
    mapping(bytes32 => address) public hooks; // poolId => hook address
    mapping(address => bool) public validHooks; // hook => isValid

    // --- Events ---
    event PoolCreated(bytes32 indexed poolId, address pool, address hook);
    event HookValidated(address indexed hook, bool isValid);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Admin Functions ---
    function setHookValidation(address hook, bool isValid) external onlyOwner {
        if (hook == address(0)) revert LibErrors.ZeroAddress();
        validHooks[hook] = isValid;
        emit HookValidated(hook, isValid);
    }

    // --- Core Functions ---
    function createPool(address token0, address token1, address hook) external returns (address pool) {
        if (token0 == address(0) || token1 == address(0)) revert LibErrors.ZeroAddress();
        if (token0 == token1) revert LibErrors.InvalidTokenPair();
        if (hook != address(0) && !validHooks[hook]) revert LibErrors.InvalidHook();

        // Ensure token0 < token1 for consistent pool ID generation
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }

        bytes32 poolId = generatePoolId(token0, token1, hook);
        if (pools[poolId] != address(0)) revert LibErrors.PoolAlreadyExists();

        // Validate hook permissions if provided
        if (hook != address(0)) {
            _validateHook(hook);
        }

        // TODO: Deploy actual pool contract
        // For now, store the hook address
        pools[poolId] = address(this); // Placeholder
        hooks[poolId] = hook;

        emit PoolCreated(poolId, address(this), hook);
        return address(this); // Placeholder
    }

    function generatePoolId(address token0, address token1, address hook) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token0, token1, hook));
    }

    function getPool(bytes32 poolId) public view returns (address) {
        return pools[poolId];
    }

    function getHook(bytes32 poolId) public view returns (address) {
        return hooks[poolId];
    }

    function getPoolId(address token0, address token1, address hook) external pure returns (bytes32) {
        // Ensure consistent ordering
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        return generatePoolId(token0, token1, hook);
    }

    // --- Internal Functions ---
    function _validateHook(address hook) internal view {
        // Basic hook validation - check if it implements required interface
        // This is a simplified validation; in production, you'd check specific hook permissions
        if (hook.code.length == 0) revert LibErrors.InvalidHook();
        
        // TODO: Add more sophisticated hook validation
        // - Check hook permissions
        // - Verify hook implements required functions
        // - Validate hook address format for Uniswap v4
    }
} 