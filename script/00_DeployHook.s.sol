// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {BaseScript} from "./base/BaseScript.sol";

import {SkySwapHooks} from "../src/SkySwapHooks.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {USYCVault} from "../src/USYCVault.sol";
import {CollateralManager} from "../src/CollateralManager.sol";

/// @notice Mines the address and deploys the SkySwapHooks.sol Hook contract
contract DeployHookScript is BaseScript {
    function run() public {
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
                | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
        );

        // Deploy required contracts first
        address mockVerifier = address(0x1); // Replace with actual verifier
        address mockLink = address(0x2); // Replace with actual LINK address
        
        // Deploy dependencies
        vm.startBroadcast();
        // Deploy OracleManager with mock addresses for demo
        OracleManager oracleManager = new OracleManager(mockVerifier, mockLink);
        USYCVault usycVault = new USYCVault();
        CollateralManager collateralManager = new CollateralManager(address(oracleManager));
        vm.stopBroadcast();

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(
            poolManager, 
            address(usycVault), 
            address(collateralManager), 
            address(oracleManager)
        );
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_FACTORY, flags, type(SkySwapHooks).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        SkySwapHooks skySwapHooks = new SkySwapHooks{salt: salt}(
            poolManager, 
            address(usycVault), 
            address(collateralManager), 
            address(oracleManager)
        );
        vm.stopBroadcast();

        require(address(skySwapHooks) == hookAddress, "DeployHookScript: Hook Address Mismatch");
    }
}
