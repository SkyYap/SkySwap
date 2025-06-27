// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SkyUSDVault} from "../src/SkyUSDVault.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";

contract SkyUSDVaultTest is Test {
    SkyUSDVault vault;
    address hook;
    address alice;
    address bob;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FlashMint(address indexed user, uint256 amount);
    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    function setUp() public {
        vault = new SkyUSDVault();
        hook = makeAddr("hook");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Set the hook
        vault.setSkySwapHooks(hook);
    }

    function testInitialState() public {
        assertEq(vault.name(), "Sky USD");
        assertEq(vault.symbol(), "skyUSD");
        assertEq(vault.decimals(), 18);
        assertEq(vault.totalSupply(), 0);
        assertEq(vault.owner(), address(this));
    }

    function testSetSkySwapHooks() public {
        address newHook = makeAddr("newHook");
        vault.setSkySwapHooks(newHook);
        // We can't directly check skySwapHooks as it's private, but we can test functionality
        
        // Should revert with zero address
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        vault.setSkySwapHooks(address(0));
    }

    function testSetSkySwapHooks_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.OnlyOwner.selector);
        vault.setSkySwapHooks(makeAddr("newHook"));
    }

    function testMint() public {
        uint256 amount = 1000e18;
        
        vm.expectEmit(true, true, false, true);
        emit Mint(alice, amount);
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, amount);
        
        vm.prank(hook);
        vault.mint(alice, amount);
        
        assertEq(vault.balanceOf(alice), amount);
        assertEq(vault.totalSupply(), amount);
        assertEq(vault.getDebt(alice), amount);
    }

    function testMint_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        vault.mint(alice, 1000e18);
    }

    function testMint_ZeroAddress() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        vault.mint(address(0), 1000e18);
    }

    function testMint_ZeroAmount() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.ZeroAmount.selector);
        vault.mint(alice, 0);
    }

    function testBurn() public {
        uint256 mintAmount = 1000e18;
        uint256 burnAmount = 300e18;
        
        // First mint tokens
        vm.prank(hook);
        vault.mint(alice, mintAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Burn(alice, burnAmount);
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, address(0), burnAmount);
        
        vm.prank(hook);
        vault.burn(alice, burnAmount);
        
        assertEq(vault.balanceOf(alice), mintAmount - burnAmount);
        assertEq(vault.totalSupply(), mintAmount - burnAmount);
    }

    function testBurn_InsufficientBalance() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InsufficientBalance.selector);
        vault.burn(alice, 1000e18);
    }

    function testRepay() public {
        uint256 amount = 1000e18;
        uint256 repayAmount = 300e18;
        
        // First mint to create debt
        vm.prank(hook);
        vault.mint(alice, amount);
        
        vm.expectEmit(true, false, false, true);
        emit Repay(alice, repayAmount);
        
        vm.prank(hook);
        vault.repay(alice, repayAmount);
        
        assertEq(vault.getDebt(alice), amount - repayAmount);
    }

    function testRepay_InsufficientDebt() public {
        vm.prank(hook);
        vm.expectRevert(LibErrors.InsufficientBalance.selector);
        vault.repay(alice, 1000e18);
    }

    function testTransfer() public {
        uint256 amount = 1000e18;
        uint256 transferAmount = 300e18;
        
        // First mint tokens
        vm.prank(hook);
        vault.mint(alice, amount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, transferAmount);
        
        vm.prank(alice);
        bool success = vault.transfer(bob, transferAmount);
        
        assertTrue(success);
        assertEq(vault.balanceOf(alice), amount - transferAmount);
        assertEq(vault.balanceOf(bob), transferAmount);
    }

    function testTransfer_InsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.InsufficientBalance.selector);
        vault.transfer(bob, 1000e18);
    }

    function testTransfer_ZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        vault.transfer(address(0), 1000e18);
    }

    function testApprove() public {
        uint256 amount = 1000e18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, bob, amount);
        
        vm.prank(alice);
        bool success = vault.approve(bob, amount);
        
        assertTrue(success);
        assertEq(vault.allowance(alice, bob), amount);
    }

    function testApprove_ZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(LibErrors.ZeroAddress.selector);
        vault.approve(address(0), 1000e18);
    }

    function testTransferFrom() public {
        uint256 mintAmount = 1000e18;
        uint256 allowanceAmount = 500e18;
        uint256 transferAmount = 300e18;
        
        // Setup: mint tokens and approve
        vm.prank(hook);
        vault.mint(alice, mintAmount);
        
        vm.prank(alice);
        vault.approve(bob, allowanceAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, address(this), transferAmount);
        
        vm.prank(bob);
        bool success = vault.transferFrom(alice, address(this), transferAmount);
        
        assertTrue(success);
        assertEq(vault.balanceOf(alice), mintAmount - transferAmount);
        assertEq(vault.balanceOf(address(this)), transferAmount);
        assertEq(vault.allowance(alice, bob), allowanceAmount - transferAmount);
    }

    function testTransferFrom_InsufficientBalance() public {
        vm.prank(alice);
        vault.approve(bob, 1000e18);
        
        vm.prank(bob);
        vm.expectRevert(LibErrors.InsufficientBalance.selector);
        vault.transferFrom(alice, address(this), 1000e18);
    }

    function testTransferFrom_InsufficientAllowance() public {
        uint256 amount = 1000e18;
        
        vm.prank(hook);
        vault.mint(alice, amount);
        
        vm.prank(bob);
        vm.expectRevert(LibErrors.InsufficientBalance.selector);
        vault.transferFrom(alice, address(this), amount);
    }

    function testFlashMint() public {
        uint256 amount = 1000e18;
        
        // Create a mock recipient that can receive flash loan
        MockFlashLoanRecipient recipient = new MockFlashLoanRecipient(vault);
        
        vm.expectEmit(true, false, false, true);
        emit FlashMint(address(recipient), amount);
        
        vm.prank(hook);
        vault.flashMint(address(recipient), amount);
        
        // Balance should be back to 0 after flash loan
        assertEq(vault.balanceOf(address(recipient)), 0);
        assertEq(vault.totalSupply(), 0);
    }

    function testFlashMint_FailsWhenNotRepaid() public {
        uint256 amount = 1000e18;
        
        // Create a recipient that doesn't repay
        MockBadFlashLoanRecipient badRecipient = new MockBadFlashLoanRecipient();
        
        vm.prank(hook);
        vm.expectRevert(LibErrors.FlashLoanNotRepaid.selector);
        vault.flashMint(address(badRecipient), amount);
    }

    function testFlashMint_OnlyHook() public {
        vm.expectRevert(LibErrors.OnlyHook.selector);
        vault.flashMint(alice, 1000e18);
    }

    function testFuzz_MintAndBurn(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);
        
        vm.prank(hook);
        vault.mint(alice, amount);
        
        assertEq(vault.balanceOf(alice), amount);
        assertEq(vault.totalSupply(), amount);
        assertEq(vault.getDebt(alice), amount);
        
        vm.prank(hook);
        vault.burn(alice, amount);
        
        assertEq(vault.balanceOf(alice), 0);
        assertEq(vault.totalSupply(), 0);
    }
}

// Mock contract for testing flash loans
contract MockFlashLoanRecipient {
    SkyUSDVault public vault;
    
    constructor(SkyUSDVault _vault) {
        vault = _vault;
    }
    
    // This would be called during flash loan callback
    // For testing, we just approve the vault to take back the tokens
    function onFlashLoan(uint256 amount) external {
        // In a real implementation, this would do something with the tokens
        // then ensure they're available for repayment
        vault.approve(address(vault), amount);
    }
}

// Mock contract that doesn't repay flash loans
contract MockBadFlashLoanRecipient {
    // Doesn't implement proper repayment logic
} 