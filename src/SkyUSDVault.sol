// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./libraries/LibErrors.sol";
import {LibTypes} from "./libraries/LibTypes.sol";

/// @title SkyUSDVault
/// @notice Manages flash mint and debt issuance/redemption of skyUSD (see .cursor/rules/uniswap-v4-hooks.md)
contract SkyUSDVault {
    // --- ERC20-like State ---
    string public constant name = "Sky USD";
    string public constant symbol = "skyUSD";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // --- Debt State ---
    mapping(address => uint256) public debt;
    address public owner;
    address public skySwapHooks;
    mapping(address => bool) public flashLoanInProgress;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FlashMint(address indexed user, uint256 amount);
    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    modifier onlyHook() {
        if (msg.sender != skySwapHooks) revert LibErrors.OnlyHook();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Admin Functions ---
    function setSkySwapHooks(address _skySwapHooks) external onlyOwner {
        if (_skySwapHooks == address(0)) revert LibErrors.ZeroAddress();
        skySwapHooks = _skySwapHooks;
    }

    // --- ERC20 Functions ---
    function transfer(address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert LibErrors.ZeroAddress();
        if (balanceOf[msg.sender] < amount) revert LibErrors.InsufficientBalance();

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (to == address(0)) revert LibErrors.ZeroAddress();
        if (balanceOf[from] < amount) revert LibErrors.InsufficientBalance();
        if (allowance[from][msg.sender] < amount) revert LibErrors.InsufficientBalance();

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (spender == address(0)) revert LibErrors.ZeroAddress();

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // --- Core Functions ---
    function flashMint(address to, uint256 amount) external onlyHook {
        if (to == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();
        if (flashLoanInProgress[to]) revert LibErrors.InvalidFlashLoanCallback();

        flashLoanInProgress[to] = true;
        
        // Mint tokens
        balanceOf[to] += amount;
        totalSupply += amount;

        emit FlashMint(to, amount);
        emit Transfer(address(0), to, amount);

        // Callback to borrower
        _flashLoanCallback(to, amount);

        // Verify repayment
        if (balanceOf[to] < amount) revert LibErrors.FlashLoanNotRepaid();
        
        // Burn repaid tokens
        balanceOf[to] -= amount;
        totalSupply -= amount;

        flashLoanInProgress[to] = false;
        emit Transfer(to, address(0), amount);
    }

    function mint(address to, uint256 amount) external onlyHook {
        if (to == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();

        balanceOf[to] += amount;
        totalSupply += amount;
        debt[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyHook {
        if (from == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();
        if (balanceOf[from] < amount) revert LibErrors.InsufficientBalance();

        balanceOf[from] -= amount;
        totalSupply -= amount;

        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
    }

    function repay(address user, uint256 amount) external onlyHook {
        if (user == address(0)) revert LibErrors.ZeroAddress();
        if (amount == 0) revert LibErrors.ZeroAmount();
        if (debt[user] < amount) revert LibErrors.InsufficientBalance();

        debt[user] -= amount;
        emit Repay(user, amount);
    }

    // --- Internal Functions ---
    function _flashLoanCallback(address recipient, uint256 amount) internal {
        // Simple callback - in production, this would call a standardized interface
        // For now, we assume the recipient handles the flash loan logic
        // TODO: Implement proper flash loan callback interface
    }

    // --- View Functions ---
    function getDebt(address user) external view returns (uint256) {
        return debt[user];
    }
} 