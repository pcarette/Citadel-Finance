// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

    /// @notice FDUSD token contract interface
    interface IFDUSDFaucet {
        function faucet(uint256 amount) external;
        function transfer(address to, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
    }
/**
 * @title FaucetLimiter
 * @notice Limits FDUSD faucet usage to 500 tokens per address per day
 */
contract FaucetLimiter {

    /// @notice FDUSD token contract
    IFDUSDFaucet public immutable fdusdToken;
    
    /// @notice Daily limit per address (500 FDUSD with 18 decimals)
    uint256 public constant DAILY_LIMIT = 500 * 1e18;
    
    /// @notice Seconds in a day
    uint256 public constant DAY_IN_SECONDS = 24 * 60 * 60;
    
    /// @notice Mapping of address to last claim timestamp
    mapping(address => uint256) public lastClaimTime;
    
    /// @notice Mapping of address to claimed amount in current day
    mapping(address => uint256) public dailyClaimedAmount;

    /// @notice Events
    event FaucetClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed token, uint256 amount);

    /// @notice Errors
    error DailyLimitExceeded();
    error InvalidAmount();
    error TransferFailed();

    /**
     * @notice Constructor
     * @param _fdusdToken Address of the FDUSD token contract
     */
    constructor(address _fdusdToken) {
        fdusdToken = IFDUSDFaucet(_fdusdToken);
    }

    /**
     * @notice Claim FDUSD tokens from faucet with daily limit
     * @param amount Amount of FDUSD to claim (max 500 per day)
     */
    function claimFDUSD(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        
        address user = msg.sender;
        uint256 currentTime = block.timestamp;
        
        // Reset daily limit if a day has passed
        if (currentTime >= lastClaimTime[user] + DAY_IN_SECONDS) {
            dailyClaimedAmount[user] = 0;
        }
        
        // Check if claim would exceed daily limit
        if (dailyClaimedAmount[user] + amount > DAILY_LIMIT) {
            revert DailyLimitExceeded();
        }
        
        // Update tracking variables
        lastClaimTime[user] = currentTime;
        dailyClaimedAmount[user] += amount;
        
        // Call faucet function to mint tokens to this contract
        fdusdToken.faucet(amount);
        
        // Transfer tokens to user
        bool success = fdusdToken.transfer(user, amount);
        if (!success) revert TransferFailed();
        
        emit FaucetClaimed(user, amount);
    }

    /**
     * @notice Get remaining daily limit for an address
     * @param user Address to check
     * @return remaining Amount that can still be claimed today
     */
    function getRemainingDailyLimit(address user) external view returns (uint256 remaining) {
        uint256 currentTime = block.timestamp;
        
        // If a day has passed, full limit is available
        if (currentTime >= lastClaimTime[user] + DAY_IN_SECONDS) {
            return DAILY_LIMIT;
        }
        
        // Otherwise, return remaining amount
        return DAILY_LIMIT - dailyClaimedAmount[user];
    }

    /**
     * @notice Get time until next reset for an address
     * @param user Address to check
     * @return timeUntilReset Seconds until the daily limit resets
     */
    function getTimeUntilReset(address user) external view returns (uint256 timeUntilReset) {
        uint256 currentTime = block.timestamp;
        uint256 nextResetTime = lastClaimTime[user] + DAY_IN_SECONDS;
        
        if (currentTime >= nextResetTime) {
            return 0;
        }
        
        return nextResetTime - currentTime;
    }

    /**
     * @notice Emergency function to withdraw tokens (only for contract owner/deployer)
     * @param token Token address to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external {
        // Simple access control - only deployer can call
        // In production, consider using OpenZeppelin's Ownable
        require(msg.sender == address(0), "Not authorized"); // This will always fail - implement proper access control
        
        IERC20(token).transfer(msg.sender, amount);
        emit EmergencyWithdraw(token, amount);
    }

    /**
     * @notice Get contract's FDUSD balance
     * @return balance Current FDUSD balance of this contract
     */
    function getContractBalance() external view returns (uint256 balance) {
        return fdusdToken.balanceOf(address(this));
    }
}