// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICToken
 * @dev Interface for Compound V2 cToken contracts
 * @notice This interface defines the functions needed to interact with Compound's cToken contracts
 */
interface ICToken {
    /**
     * @notice Supply assets to Compound and receive cTokens
     * @dev Sender must have approved the cToken contract to spend the underlying asset
     * @param mintAmount The amount of underlying asset to supply
     * @return uint256 0 on success, otherwise an error code
     */
    function mint(uint256 mintAmount) external returns (uint256);

    /**
     * @notice Redeem a specific amount of underlying assets from Compound
     * @dev Burns cTokens and transfers underlying assets to the caller
     * @param redeemAmount The amount of underlying asset to redeem
     * @return uint256 0 on success, otherwise an error code
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Get the underlying balance of an account
     * @dev Calculates the underlying balance based on cToken balance and exchange rate
     * @param owner The address whose balance to query
     * @return uint256 The amount of underlying asset
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get the current exchange rate from cTokens to underlying
     * @dev The exchange rate is scaled by 1e18
     * @return uint256 The current exchange rate
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Get the address of the underlying asset
     * @return address The underlying asset address
     */
    function underlying() external view returns (address);
}
