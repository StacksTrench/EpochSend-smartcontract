// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICToken.sol";

/**
 * @title MockCToken
 * @dev Mock implementation of Compound's cToken for testing
 * @notice This contract simulates Compound's cToken behavior for testing purposes
 */
contract MockCToken is ICToken {
    using SafeERC20 for IERC20;

    IERC20 public immutable underlyingToken;
    uint256 public exchangeRate;
    
    // Track cToken balances
    mapping(address => uint256) public cTokenBalances;
    
    // Track total supply of cTokens
    uint256 public totalCTokenSupply;
    
    // Initial exchange rate (0.02 * 1e18)
    uint256 private constant INITIAL_EXCHANGE_RATE = 0.02e18;
    
    /**
     * @dev Constructor
     * @param underlying_ The address of the underlying ERC20 token
     */
    constructor(address underlying_) {
        require(underlying_ != address(0), "MockCToken: underlying is zero address");
        underlyingToken = IERC20(underlying_);
        exchangeRate = INITIAL_EXCHANGE_RATE;
    }

    /**
     * @notice Supply assets to the mock cToken
     * @param mintAmount The amount of underlying asset to supply
     * @return uint256 0 on success, non-zero on failure
     */
    function mint(uint256 mintAmount) external override returns (uint256) {
        if (mintAmount == 0) return 1; // Error code 1 for zero amount
        
        // Transfer underlying tokens from sender
        try underlyingToken.transferFrom(msg.sender, address(this), mintAmount) {
            // Calculate cTokens to mint based on exchange rate
            // cTokens = mintAmount / exchangeRate
            uint256 cTokensToMint = (mintAmount * 1e18) / exchangeRate;
            
            // Update balances
            cTokenBalances[msg.sender] += cTokensToMint;
            totalCTokenSupply += cTokensToMint;
            
            return 0; // Success
        } catch {
            return 2; // Error code 2 for transfer failure
        }
    }

    /**
     * @notice Redeem a specific amount of underlying assets
     * @param redeemAmount The amount of underlying asset to redeem
     * @return uint256 0 on success, non-zero on failure
     */
    function redeemUnderlying(uint256 redeemAmount) external override returns (uint256) {
        if (redeemAmount == 0) return 1; // Error code 1 for zero amount
        
        // Calculate cTokens needed to redeem this amount
        // cTokens = redeemAmount / exchangeRate
        uint256 cTokensToRedeem = (redeemAmount * 1e18) / exchangeRate;
        
        // Check if sender has enough cTokens
        if (cTokenBalances[msg.sender] < cTokensToRedeem) return 3; // Error code 3 for insufficient balance
        
        // Check if contract has enough underlying tokens
        if (underlyingToken.balanceOf(address(this)) < redeemAmount) return 4; // Error code 4 for insufficient liquidity
        
        // Update balances
        cTokenBalances[msg.sender] -= cTokensToRedeem;
        totalCTokenSupply -= cTokensToRedeem;
        
        // Transfer underlying tokens to sender
        try underlyingToken.transfer(msg.sender, redeemAmount) {
            return 0; // Success
        } catch {
            // Revert balance changes on transfer failure
            cTokenBalances[msg.sender] += cTokensToRedeem;
            totalCTokenSupply += cTokensToRedeem;
            return 2; // Error code 2 for transfer failure
        }
    }

    /**
     * @notice Get the underlying balance of an account
     * @param owner The address whose balance to query
     * @return uint256 The amount of underlying asset
     */
    function balanceOfUnderlying(address owner) external override returns (uint256) {
        // underlying = cTokenBalance * exchangeRate
        return (cTokenBalances[owner] * exchangeRate) / 1e18;
    }

    /**
     * @notice Get the current exchange rate
     * @return uint256 The current exchange rate (scaled by 1e18)
     */
    function exchangeRateCurrent() external override returns (uint256) {
        return exchangeRate;
    }

    /**
     * @notice Get the address of the underlying asset
     * @return address The underlying asset address
     */
    function underlying() external view override returns (address) {
        return address(underlyingToken);
    }

    /*//////////////////////////////////////////////////////////////
                        TEST HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set a custom exchange rate for testing yield scenarios
     * @param newRate The new exchange rate (scaled by 1e18)
     */
    function setExchangeRate(uint256 newRate) external {
        require(newRate > 0, "MockCToken: exchange rate must be positive");
        exchangeRate = newRate;
    }

    /**
     * @dev Get cToken balance of an account
     * @param account The address to query
     * @return The cToken balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return cTokenBalances[account];
    }

    /**
     * @dev Simulate interest accrual by increasing exchange rate
     * @param interestBasisPoints Interest to accrue in basis points (e.g., 100 = 1%)
     */
    function accrueInterest(uint256 interestBasisPoints) external {
        require(interestBasisPoints > 0, "MockCToken: interest must be positive");
        exchangeRate = exchangeRate + (exchangeRate * interestBasisPoints) / 10000;
    }
}
