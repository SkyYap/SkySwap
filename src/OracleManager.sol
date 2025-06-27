// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibErrors} from "./libraries/LibErrors.sol";
import {LibTypes} from "./libraries/LibTypes.sol";

// Chainlink Data Streams interfaces
interface IVerifierProxy {
    function verify(bytes calldata signedReport) external payable returns (bytes memory verifierResponse);
    function s_feeManager() external view returns (address);
}

interface IFeeManager {
    function getFeeAndReward(address subscriber, bytes memory unverifiedReport, address quoteAddress) 
        external view returns (uint256 fee, uint256 reward);
    function i_nativeAddress() external view returns (address);
}



// Data Streams report structure
struct Report {
    bytes32 feedId;
    uint32 validFromTimestamp;
    uint32 observationsTimestamp;
    uint192 nativeFee;
    uint192 linkFee;
    uint32 expiresAt;
    int192 price;
    int192 bid;
    int192 ask;
}

/// @title OracleManager
/// @notice Manages price feeds and peg bands for SkySwap (see .cursor/rules/uniswap-v4-hooks.md)
contract OracleManager {
    // --- State ---
    address public owner;
    mapping(address => LibTypes.OracleData) public oracleData;
    mapping(address => LibTypes.DataStreamConfig) public dataStreamConfigs;
    
    IVerifierProxy public immutable verifierProxy;
    address public immutable linkAddress;
    
    uint256 public constant MAX_PEG_BAND = 1000; // 10% max deviation
    uint256 public constant DATA_STREAMS_STALENESS_THRESHOLD = 300; // 5 minutes for data streams

    // --- Events ---
    event DataStreamConfigured(address indexed token, bytes32 feedId, address verifier);
    event DataStreamPriceUpdated(address indexed token, uint256 price, uint256 timestamp);
    event PegBandSet(address indexed token, uint256 bandBps);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.OnlyOwner();
        _;
    }

    constructor(address _verifierProxy, address _linkAddress) {
        owner = msg.sender;
        verifierProxy = IVerifierProxy(_verifierProxy);
        linkAddress = _linkAddress;
    }

    // --- Admin Functions ---
    function configureDataStream(
        address token,
        bytes32 feedId,
        uint8 decimals
    ) external onlyOwner {
        if (token == address(0) || feedId == bytes32(0)) revert LibErrors.ZeroAddress();
        
        dataStreamConfigs[token] = LibTypes.DataStreamConfig({
            feedId: feedId,
            decimals: decimals,
            isActive: true
        });
        
        emit DataStreamConfigured(token, feedId, address(verifierProxy));
    }

    function toggleDataStream(address token, bool isActive) external onlyOwner {
        dataStreamConfigs[token].isActive = isActive;
    }

    function setPegBand(address token, uint256 bandBps) external onlyOwner {
        if (token == address(0)) revert LibErrors.ZeroAddress();
        if (bandBps > MAX_PEG_BAND) revert LibErrors.InvalidParameter();
        
        oracleData[token].pegBand = bandBps;
        
        emit PegBandSet(token, bandBps);
    }

    // --- Core Functions ---
    function getPrice(address token) public view returns (uint256 price) {
        // Check if data stream is configured and active
        LibTypes.DataStreamConfig memory streamConfig = dataStreamConfigs[token];
        if (!streamConfig.isActive || streamConfig.feedId == bytes32(0)) {
            revert LibErrors.DataStreamNotConfigured();
        }

        // For data streams, we need cached price since we can't pull without signed report
        LibTypes.OracleData memory data = oracleData[token];
        if (data.price > 0 && block.timestamp - data.lastUpdate <= DATA_STREAMS_STALENESS_THRESHOLD) {
            return data.price;
        }
        
        revert LibErrors.StalePrice(); // Need fresh data stream update
    }

    function getPriceWithReport(address token, bytes calldata signedReport) external payable returns (uint256 price) {
        LibTypes.DataStreamConfig memory streamConfig = dataStreamConfigs[token];
        if (!streamConfig.isActive || streamConfig.feedId == bytes32(0)) {
            revert LibErrors.DataStreamNotConfigured();
        }

        // Get fee for verification
        IFeeManager feeManager = IFeeManager(verifierProxy.s_feeManager());
        uint256 fee = getFee(signedReport);
        
        if (msg.value < fee) {
            revert LibErrors.InsufficientFee();
        }

        // Verify the signed report
        bytes memory verifiedReportData = verifierProxy.verify{value: fee}(signedReport);
        Report memory report = abi.decode(verifiedReportData, (Report));

        // Validate the report
        if (report.feedId != streamConfig.feedId) {
            revert LibErrors.InvalidFeedId();
        }
        if (report.expiresAt < block.timestamp) {
            revert LibErrors.ReportExpired();
        }
        if (report.price <= 0) {
            revert LibErrors.InvalidPrice();
        }

        // Normalize price to 18 decimals
        price = uint256(uint192(report.price)) * (10 ** (18 - streamConfig.decimals));

        // Cache the price
        oracleData[token].price = price;
        oracleData[token].lastUpdate = block.timestamp;

        emit DataStreamPriceUpdated(token, price, block.timestamp);

        // Refund excess payment
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }

        return price;
    }



    function isWithinPegBand(address token, uint256 price) public view returns (bool) {
        LibTypes.OracleData memory data = oracleData[token];
        if (data.pegBand == 0) return true; // No peg band set
        
        uint256 oraclePrice = getPrice(token);
        uint256 deviation = price > oraclePrice 
            ? ((price - oraclePrice) * 10000) / oraclePrice
            : ((oraclePrice - price) * 10000) / oraclePrice;
            
        return deviation <= data.pegBand;
    }



    function getCachedPrice(address token) external view returns (uint256 price, uint256 lastUpdate) {
        LibTypes.OracleData memory data = oracleData[token];
        return (data.price, data.lastUpdate);
    }

    function getFee(bytes calldata signedReport) public view returns (uint256 fee) {
        IFeeManager feeManager = IFeeManager(verifierProxy.s_feeManager());
        address nativeAddress = feeManager.i_nativeAddress();
        (fee, ) = feeManager.getFeeAndReward(address(this), signedReport, nativeAddress);
    }

    function isDataStreamActive(address token) external view returns (bool) {
        return dataStreamConfigs[token].isActive && dataStreamConfigs[token].feedId != bytes32(0);
    }

    function getDataStreamConfig(address token) external view returns (LibTypes.DataStreamConfig memory) {
        return dataStreamConfigs[token];
    }

    // Receive function to handle ETH payments for data stream verification
    receive() external payable {}
} 