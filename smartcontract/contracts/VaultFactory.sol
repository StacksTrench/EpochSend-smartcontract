// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./UserVault.sol";

/**
 * @title VaultFactory
 * @dev Factory contract for creating and managing user vaults on SmartX platform
 * @notice This contract handles user registration and vault deployment
 */
contract VaultFactory is Ownable {
    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Thrown when user tries to register twice
    error AlreadyRegistered();

    /// @dev Thrown when querying data for unregistered user
    error NotRegistered();

    /// @dev Thrown when username exceeds maximum length
    error UsernameTooLong();

    /// @dev Thrown when bio exceeds maximum length
    error BioTooLong();

    /// @dev Thrown when username is empty
    error EmptyUsername();

    /// @dev Thrown when trying to create vault for asset without price feed
    error PriceFeedNotSet();

    /// @dev Thrown when vault deployment fails
    error VaultCreationFailed();

    /// @dev Thrown when caller is not an admin
    error NotAdmin();

    /// @dev Thrown when adding an admin that already exists
    error AdminAlreadyExists();

    /// @dev Thrown when removing an admin that does not exist
    error AdminDoesNotExist();

    /// @dev Thrown when trying to remove the deployer admin
    error CannotRemoveDeployer();

    /// @dev Thrown when trying to set a zero address
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Maximum allowed username length
    uint256 public constant MAX_USERNAME_LENGTH = 20;

    /// @dev Maximum allowed bio length
    uint256 public constant MAX_BIO_LENGTH = 30;

    /// @dev Mapping to track registered users
    mapping(address => bool) private registeredUsers;

    /// @dev Mapping to store usernames
    mapping(address => string) private userUsernames;

    /// @dev Mapping to store user bios
    mapping(address => string) private userBios;

    /// @dev Mapping to store registration timestamps
    mapping(address => uint256) private userRegistrationTimestamps;

    /// @dev Mapping to store price feeds for assets
    mapping(address => address) public assetPriceFeeds;

    /// @dev Mapping to track vaults created by each user
    mapping(address => address[]) private userVaults;

    /// @dev Mapping to track vault owners
    mapping(address => address) private vaultOwners;

    /// @dev Mapping to track vault creation timestamps
    mapping(address => uint256) private vaultCreatedAt;

    /// @dev Total number of vaults created
    uint256 private totalVaults;

    /// @dev Address of the initial deployer/admin
    address public deployerAdmin;

    /// @dev Mapping to track admin status
    mapping(address => bool) private admins;

    /// @dev Total number of admins
    uint256 public adminCount;

    /// @dev Aave lending pool address
    address public aaveLendingPool;

    /// @dev Compound comptroller address
    address public compoundComptroller;

    /// @dev Uniswap router address
    address public uniswapRouter;

    /// @dev WETH token address
    address public wethAddress;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a user registers
     * @param user The address of the registered user
     * @param username The username chosen by the user
     * @param timestamp The block timestamp of registration
     */
    event UserRegistered(
        address indexed user,
        string username,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a price feed is updated
     * @param asset The asset address
     * @param feed The price feed address
     */
    event PriceFeedUpdated(address indexed asset, address indexed feed);

    /**
     * @dev Emitted when a vault is created
     * @param owner The address of the vault owner
     * @param vault The address of the created vault
     * @param asset The address of the vault's underlying asset
     * @param timestamp The block timestamp of vault creation
     */
    event VaultCreated(
        address indexed owner,
        address indexed vault,
        address indexed asset,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a new admin is added
     * @param admin The address of the new admin
     * @param addedBy The address of the admin who added the new admin
     */
    event AdminAdded(address indexed admin, address indexed addedBy);

    /**
     * @dev Emitted when an admin is removed
     * @param admin The address of the removed admin
     * @param removedBy The address of the admin who removed the admin
     */
    event AdminRemoved(address indexed admin, address indexed removedBy);

    /**
     * @dev Emitted when a protocol address is set
     * @param protocol The name of the protocol
     * @param newAddress The new address for the protocol
     * @param setBy The address of the admin who set the address
     */
    event ProtocolAddressSet(string indexed protocol, address indexed newAddress, address indexed setBy);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor to initialize the factory
     * @param initialOwner The address of the initial owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        deployerAdmin = initialOwner;
        admins[initialOwner] = true;
        adminCount = 1;
        emit AdminAdded(initialOwner, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to restrict access to admins only
     */
    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        USER REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Register a new user with username and bio
     * @param username The desired username (max 20 characters)
     * @param bio The user's bio (max 30 characters, can be empty)
     * @notice Users can only register once
     * @notice Username cannot be empty and must be within length limits
     */
    function registerUser(string calldata username, string calldata bio) external {
        // Check if user is already registered
        if (registeredUsers[msg.sender]) revert AlreadyRegistered();

        // Validate username
        if (bytes(username).length == 0) revert EmptyUsername();
        if (bytes(username).length > MAX_USERNAME_LENGTH) revert UsernameTooLong();

        // Validate bio (can be empty, but not too long)
        if (bytes(bio).length > MAX_BIO_LENGTH) revert BioTooLong();

        // Store user data
        registeredUsers[msg.sender] = true;
        userUsernames[msg.sender] = username;
        userBios[msg.sender] = bio;
        userRegistrationTimestamps[msg.sender] = block.timestamp;

        // Emit event
        emit UserRegistered(msg.sender, username, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE FEED MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set the price feed for a supported asset
     * @param asset The asset address
     * @param feed The Chainlink price feed address
     */
    /**
     * @dev Set the price feed for a supported asset
     * @param asset The asset address
     * @param feed The Chainlink price feed address
     */
    function setAssetPriceFeed(address asset, address feed) external onlyAdmin {
        require(asset != address(0), "VaultFactory: asset is zero address");
        require(feed != address(0), "VaultFactory: feed is zero address");
        
        assetPriceFeeds[asset] = feed;
        emit PriceFeedUpdated(asset, feed);
    }

    /*//////////////////////////////////////////////////////////////
                         VAULT CREATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Create a new vault for a registered user
     * @param asset The address of the underlying asset token
     * @param name The name of the vault share token
     * @param symbol The symbol of the vault share token
     * @return vault The address of the created vault
     * @notice User must be registered before creating a vault
     * @notice Price feed must be set for the asset
     */
    function createVault(
        address asset,
        string calldata name,
        string calldata symbol
    ) external returns (address vault) {
        // Check user is registered
        if (!registeredUsers[msg.sender]) revert NotRegistered();

        // Check price feed is set for this asset
        address priceFeed = assetPriceFeeds[asset];
        if (priceFeed == address(0)) revert PriceFeedNotSet();

        // Deploy new UserVault contract
        vault = address(
            new UserVault(
                asset,
                msg.sender,
                address(this),
                name,
                symbol,
                priceFeed
            )
        );

        // Verify deployment succeeded
        if (vault == address(0)) revert VaultCreationFailed();

        // Track vault in user's vault list
        userVaults[msg.sender].push(vault);

        // Record vault owner
        vaultOwners[vault] = msg.sender;

        // Record creation timestamp
        vaultCreatedAt[vault] = block.timestamp;

        // Increment total vaults counter
        totalVaults++;

        // Emit event
        emit VaultCreated(msg.sender, vault, asset, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Check if a user is registered
     * @param user The address to check
     * @return bool True if user is registered, false otherwise
     */
    function isUserRegistered(address user) external view returns (bool) {
        return registeredUsers[user];
    }

    /**
     * @dev Get complete user information
     * @param user The address of the user
     * @return username The user's username
     * @return bio The user's bio
     * @return registrationTimestamp The timestamp when user registered
     * @notice Reverts if user is not registered
     */
    function getUserInfo(address user)
        external
        view
        returns (
            string memory username,
            string memory bio,
            uint256 registrationTimestamp
        )
    {
        if (!registeredUsers[user]) revert NotRegistered();

        return (
            userUsernames[user],
            userBios[user],
            userRegistrationTimestamps[user]
        );
    }

    /**
     * @dev Get username for a registered user
     * @param user The address of the user
     * @return The user's username
     * @notice Reverts if user is not registered
     */
    function getUsername(address user) external view returns (string memory) {
        if (!registeredUsers[user]) revert NotRegistered();
        return userUsernames[user];
    }

    /**
     * @dev Get bio for a registered user
     * @param user The address of the user
     * @return The user's bio
     * @notice Reverts if user is not registered
     */
    function getBio(address user) external view returns (string memory) {
        if (!registeredUsers[user]) revert NotRegistered();
        return userBios[user];
    }

    /**
     * @dev Get registration timestamp for a registered user
     * @param user The address of the user
     * @return The timestamp when user registered
     * @notice Reverts if user is not registered
     */
    function getRegistrationTimestamp(address user) external view returns (uint256) {
        if (!registeredUsers[user]) revert NotRegistered();
        return userRegistrationTimestamps[user];
    }

    /**
     * @dev Get all vaults created by a user
     * @param user The address of the user
     * @return An array of vault addresses
     */
    function getUserVaults(address user) external view returns (address[] memory) {
        return userVaults[user];
    }

    /**
     * @dev Get the owner of a vault
     * @param vault The address of the vault
     * @return The address of the vault owner
     */
    function getVaultOwner(address vault) external view returns (address) {
        return vaultOwners[vault];
    }

    /**
     * @dev Get the total number of vaults created
     * @return The total vault count
     */
    function getTotalVaults() external view returns (uint256) {
        return totalVaults;
    }

    /**
     * @dev Get the number of vaults created by a user
     * @param user The address of the user
     * @return The number of vaults
     */
    function getVaultCount(address user) external view returns (uint256) {
        return userVaults[user].length;
    }

    /**
     * @dev Get the creation timestamp of a vault
     * @param vault The address of the vault
     * @return The timestamp when vault was created
     */
    function getVaultCreationTime(address vault) external view returns (uint256) {
        return vaultCreatedAt[vault];
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Add a new admin
     * @param newAdmin The address of the new admin
     */
    function addAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert("Invalid address");
        if (admins[newAdmin]) revert AdminAlreadyExists();

        admins[newAdmin] = true;
        adminCount++;
        emit AdminAdded(newAdmin, msg.sender);
    }

    /**
     * @dev Remove an existing admin
     * @param admin The address of the admin to remove
     */
    function removeAdmin(address admin) external onlyAdmin {
        if (!admins[admin]) revert AdminDoesNotExist();
        if (admin == deployerAdmin) revert CannotRemoveDeployer();

        admins[admin] = false;
        adminCount--;
        emit AdminRemoved(admin, msg.sender);
    }

    /**
     * @dev Check if an address is an admin
     * @param account The address to check
     * @return bool True if the address is an admin
     */
    function isAdmin(address account) external view returns (bool) {
        return admins[account];
    }

    /**
     * @dev Get the total number of admins
     * @return The number of admins
     */
    function getAdminCount() external view returns (uint256) {
        return adminCount;
    }

    /*//////////////////////////////////////////////////////////////
                    PROTOCOL ADDRESS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set the Aave lending pool address
     * @param aaveAddress The address of the Aave lending pool
     */
    function setAaveAddress(address aaveAddress) external onlyAdmin {
        if (aaveAddress == address(0)) revert ZeroAddress();
        aaveLendingPool = aaveAddress;
        emit ProtocolAddressSet("Aave", aaveAddress, msg.sender);
    }

    /**
     * @dev Set the Compound comptroller address
     * @param compoundAddress The address of the Compound comptroller
     */
    function setCompoundAddress(address compoundAddress) external onlyAdmin {
        if (compoundAddress == address(0)) revert ZeroAddress();
        compoundComptroller = compoundAddress;
        emit ProtocolAddressSet("Compound", compoundAddress, msg.sender);
    }

    /**
     * @dev Set the Uniswap router address
     * @param uniswapAddress The address of the Uniswap router
     */
    function setUniswapAddress(address uniswapAddress) external onlyAdmin {
        if (uniswapAddress == address(0)) revert ZeroAddress();
        uniswapRouter = uniswapAddress;
        emit ProtocolAddressSet("Uniswap", uniswapAddress, msg.sender);
    }

    /**
     * @dev Set the WETH token address
     * @param wethAddr The address of the WETH token
     */
    function setWETHAddress(address wethAddr) external onlyAdmin {
        if (wethAddr == address(0)) revert ZeroAddress();
        wethAddress = wethAddr;
        emit ProtocolAddressSet("WETH", wethAddr, msg.sender);
    }

    /**
     * @dev Get the Aave lending pool address
     * @return The address of the Aave lending pool
     */
    function getAaveAddress() external view returns (address) {
        return aaveLendingPool;
    }

    /**
     * @dev Get the Compound comptroller address
     * @return The address of the Compound comptroller
     */
    function getCompoundAddress() external view returns (address) {
        return compoundComptroller;
    }

    /**
     * @dev Get the Uniswap router address
     * @return The address of the Uniswap router
     */
    function getUniswapAddress() external view returns (address) {
        return uniswapRouter;
    }

    /**
     * @dev Get the WETH token address
     * @return The address of the WETH token
     */
    function getWETHAddress() external view returns (address) {
        return wethAddress;
    }
}
