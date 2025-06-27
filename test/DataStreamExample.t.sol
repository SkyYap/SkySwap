// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {OracleManager} from "../src/OracleManager.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";
import {LibTypes} from "../src/libraries/LibTypes.sol";

/// @title DataStreamExample
/// @notice Example test showing how to use Chainlink Data Streams with SkySwap
contract DataStreamExampleTest is Test {
    OracleManager oracleManager;
    address mockVerifier;
    address mockLink;
    
    // Example feed IDs (these would be real Chainlink Data Stream feed IDs)
    bytes32 constant ETH_USD_FEED_ID = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 constant USDC_USD_FEED_ID = 0x0000000000000000000000000000000000000000000000000000000000000002;
    
    address tokenETH;
    address tokenUSDC;
    address alice;

    function setUp() public {
        // Deploy mock verifier and link
        mockVerifier = address(new MockVerifierProxy());
        mockLink = makeAddr("link");
        
        // Deploy OracleManager with Data Streams support
        oracleManager = new OracleManager(mockVerifier, mockLink);
        
        // Create mock tokens
        tokenETH = makeAddr("ETH");
        tokenUSDC = makeAddr("USDC");
        alice = makeAddr("alice");
        
        // Configure Data Streams for tokens
        oracleManager.configureDataStream(tokenETH, ETH_USD_FEED_ID, 8); // ETH/USD with 8 decimals  
        oracleManager.configureDataStream(tokenUSDC, USDC_USD_FEED_ID, 8); // USDC/USD with 8 decimals
    }

    function testConfigureDataStream() public {
        LibTypes.DataStreamConfig memory config = oracleManager.getDataStreamConfig(tokenETH);
        
        assertEq(config.feedId, ETH_USD_FEED_ID);
        assertEq(config.decimals, 8);
        assertTrue(config.isActive);
        assertTrue(oracleManager.isDataStreamActive(tokenETH));
    }

    function testGetPriceWithDataStream() public {
        // Create a mock signed report
        bytes memory signedReport = createMockSignedReport(ETH_USD_FEED_ID, 2500e8); // $2500 ETH
        
        // Get price with report (requires ETH payment for verification)
        vm.deal(address(this), 1 ether);
        uint256 price = oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, signedReport);
        
        // Price should be normalized to 18 decimals
        assertEq(price, 2500e18);
        
        // Price should be cached
        (uint256 cachedPrice, uint256 lastUpdate) = oracleManager.getCachedPrice(tokenETH);
        assertEq(cachedPrice, 2500e18);
        assertEq(lastUpdate, block.timestamp);
    }

    function testGetPriceReturnsStale() public {
        // Without fresh report, getPrice should revert with StalePrice
        vm.expectRevert(LibErrors.StalePrice.selector);
        oracleManager.getPrice(tokenETH);
    }

    function testGetPriceWithCachedData() public {
        // First, update with fresh data
        bytes memory signedReport = createMockSignedReport(ETH_USD_FEED_ID, 2500e8);
        vm.deal(address(this), 1 ether);
        oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, signedReport);
        
        // Now getPrice should return cached data since it's fresh
        uint256 price = oracleManager.getPrice(tokenETH);
        assertEq(price, 2500e18);
    }

    function testGetPriceAfterStalenessThreshold() public {
        // First, update with fresh data
        bytes memory signedReport = createMockSignedReport(ETH_USD_FEED_ID, 2500e8);
        vm.deal(address(this), 1 ether);
        oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, signedReport);
        
        // Fast forward past staleness threshold (5 minutes)
        vm.warp(block.timestamp + 301);
        
        // Now getPrice should revert with StalePrice
        vm.expectRevert(LibErrors.StalePrice.selector);
        oracleManager.getPrice(tokenETH);
    }

    function testPegBandWithDataStreams() public {
        // Configure and update ETH price
        bytes memory signedReport = createMockSignedReport(ETH_USD_FEED_ID, 2500e8);
        vm.deal(address(this), 1 ether);
        oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, signedReport);
        
        // Set peg band to 5%
        oracleManager.setPegBand(tokenETH, 500);
        
        // Test prices within peg band
        assertTrue(oracleManager.isWithinPegBand(tokenETH, 2625e18)); // +5%
        assertTrue(oracleManager.isWithinPegBand(tokenETH, 2375e18)); // -5%
        
        // Test prices outside peg band
        assertFalse(oracleManager.isWithinPegBand(tokenETH, 2650e18)); // +6%
        assertFalse(oracleManager.isWithinPegBand(tokenETH, 2350e18)); // -6%
    }

    function testDataStreamNotConfigured() public {
        address unknownToken = makeAddr("unknown");
        
        vm.expectRevert(LibErrors.DataStreamNotConfigured.selector);
        oracleManager.getPrice(unknownToken);
    }

    function testInvalidFeedId() public {
        bytes32 wrongFeedId = 0x0000000000000000000000000000000000000000000000000000000000000999;
        bytes memory signedReport = createMockSignedReport(wrongFeedId, 2500e8);
        
        vm.deal(address(this), 1 ether);
        vm.expectRevert(LibErrors.InvalidFeedId.selector);
        oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, signedReport);
    }

    function testExpiredReport() public {
        bytes memory expiredReport = createMockSignedReportWithExpiry(ETH_USD_FEED_ID, 2500e8, uint32(block.timestamp - 1));
        
        vm.deal(address(this), 1 ether);
        vm.expectRevert(LibErrors.ReportExpired.selector);
        oracleManager.getPriceWithReport{value: 0.001 ether}(tokenETH, expiredReport);
    }

    // Helper function to create mock signed reports for testing
    function createMockSignedReport(
        bytes32 feedId, 
        int192 price
    ) internal view returns (bytes memory) {
        return createMockSignedReportWithExpiry(feedId, price, uint32(block.timestamp + 300)); // Valid for 5 minutes
    }

    function createMockSignedReportWithExpiry(
        bytes32 feedId, 
        int192 price, 
        uint32 expiresAt
    ) internal view returns (bytes memory) {
        // Create a mock report structure
        bytes memory reportData = abi.encode(
            feedId, 
            uint32(block.timestamp), 
            uint32(block.timestamp), 
            uint192(0), 
            uint192(0), 
            expiresAt, 
            price, 
            int192(0), 
            int192(0)
        );
        
        // In a real implementation, this would be signed by Chainlink DON
        return abi.encode(reportData);
    }

    // Receive function to handle refunds
    receive() external payable {}
}

// Mock Verifier Proxy for testing
contract MockVerifierProxy {
    function verify(bytes calldata signedReport) external payable returns (bytes memory) {
        require(msg.value >= 0.001 ether, "Insufficient fee");
        
        // Decode the report from the signed report
        (bytes memory reportData) = abi.decode(signedReport, (bytes));
        
        return reportData;
    }
    
    function s_feeManager() external returns (address) {
        return address(new MockFeeManager());
    }
}

// Mock Fee Manager for testing
contract MockFeeManager {
    function getFeeAndReward(
        address,
        bytes memory,
        address
    ) external pure returns (uint256 fee, uint256 reward) {
        return (0.001 ether, 0);
    }
    
    function i_nativeAddress() external view returns (address) {
        return address(0); // Native ETH
    }
} 