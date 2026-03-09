import { expect } from "chai";
import { ethers } from "hardhat";
import { VaultFactory, MockERC20, ChainlinkMock } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("VaultFactory - User Registration", function () {
  let factory: VaultFactory;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy VaultFactory
    const VaultFactoryFactory = await ethers.getContractFactory("VaultFactory");
    factory = (await VaultFactoryFactory.deploy(owner.address)) as unknown as VaultFactory;
    await factory.waitForDeployment();
  });


  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should set correct constants", async function () {
      expect(await factory.MAX_USERNAME_LENGTH()).to.equal(20);
      expect(await factory.MAX_BIO_LENGTH()).to.equal(30);
    });
  });

  describe("User Registration", function () {
    const validUsername = "Alice";
    const validBio = "DeFi enthusiast";

    it("Should allow user to register with valid username and bio", async function () {
      await expect(factory.connect(user1).registerUser(validUsername, validBio))
        .to.emit(factory, "UserRegistered")
        .withArgs(user1.address, validUsername, anyValue);

      expect(await factory.isUserRegistered(user1.address)).to.be.true;
    });

    it("Should store username correctly", async function () {
      await factory.connect(user1).registerUser(validUsername, validBio);
      expect(await factory.getUsername(user1.address)).to.equal(validUsername);
    });

    it("Should store bio correctly", async function () {
      await factory.connect(user1).registerUser(validUsername, validBio);
      expect(await factory.getBio(user1.address)).to.equal(validBio);
    });

    it("Should store registration timestamp", async function () {
      const tx = await factory.connect(user1).registerUser(validUsername, validBio);
      const receipt = await tx.wait();
      const block = await ethers.provider.getBlock(receipt!.blockNumber);
      
      expect(await factory.getRegistrationTimestamp(user1.address)).to.equal(block!.timestamp);
    });

    it("Should return complete user info", async function () {
      await factory.connect(user1).registerUser(validUsername, validBio);
      const [username, bio, timestamp] = await factory.getUserInfo(user1.address);
      
      expect(username).to.equal(validUsername);
      expect(bio).to.equal(validBio);
      expect(timestamp).to.be.gt(0);
    });

    it("Should allow registration with empty bio", async function () {
      await expect(factory.connect(user1).registerUser(validUsername, ""))
        .to.emit(factory, "UserRegistered");

      expect(await factory.getBio(user1.address)).to.equal("");
    });

    it("Should allow multiple users to register", async function () {
      await factory.connect(user1).registerUser("Alice", "Bio1");
      await factory.connect(user2).registerUser("Bob", "Bio2");
      await factory.connect(user3).registerUser("Charlie", "Bio3");

      expect(await factory.isUserRegistered(user1.address)).to.be.true;
      expect(await factory.isUserRegistered(user2.address)).to.be.true;
      expect(await factory.isUserRegistered(user3.address)).to.be.true;

      expect(await factory.getUsername(user1.address)).to.equal("Alice");
      expect(await factory.getUsername(user2.address)).to.equal("Bob");
      expect(await factory.getUsername(user3.address)).to.equal("Charlie");
    });
  });

  describe("Username Validation", function () {
    it("Should revert on empty username", async function () {
      await expect(
        factory.connect(user1).registerUser("", "Valid bio")
      ).to.be.revertedWithCustomError(factory, "EmptyUsername");
    });

    it("Should accept username with exactly 20 characters", async function () {
      const username20 = "12345678901234567890"; // Exactly 20 chars
      await expect(factory.connect(user1).registerUser(username20, "Bio"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should revert on username with 21 characters", async function () {
      const username21 = "123456789012345678901"; // 21 chars
      await expect(
        factory.connect(user1).registerUser(username21, "Bio")
      ).to.be.revertedWithCustomError(factory, "UsernameTooLong");
    });

    it("Should accept username with 1 character", async function () {
      await expect(factory.connect(user1).registerUser("A", "Bio"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle special characters in username", async function () {
      await expect(factory.connect(user1).registerUser("Alice_123", "Bio"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle unicode characters in username", async function () {
      await expect(factory.connect(user1).registerUser("Alice🚀", "Bio"))
        .to.emit(factory, "UserRegistered");
    });
  });

  describe("Bio Validation", function () {
    it("Should accept bio with exactly 30 characters", async function () {
      const bio30 = "123456789012345678901234567890"; // Exactly 30 chars
      await expect(factory.connect(user1).registerUser("Alice", bio30))
        .to.emit(factory, "UserRegistered");
    });

    it("Should revert on bio with 31 characters", async function () {
      const bio31 = "1234567890123456789012345678901"; // 31 chars
      await expect(
        factory.connect(user1).registerUser("Alice", bio31)
      ).to.be.revertedWithCustomError(factory, "BioTooLong");
    });

    it("Should accept empty bio", async function () {
      await expect(factory.connect(user1).registerUser("Alice", ""))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle special characters in bio", async function () {
      await expect(factory.connect(user1).registerUser("Alice", "DeFi & NFT lover!"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle unicode characters in bio", async function () {
      await expect(factory.connect(user1).registerUser("Alice", "Crypto enthusiast 🚀"))
        .to.emit(factory, "UserRegistered");
    });
  });

  describe("Duplicate Registration", function () {
    const username = "Alice";
    const bio = "DeFi enthusiast";

    it("Should prevent duplicate registration", async function () {
      await factory.connect(user1).registerUser(username, bio);
      
      await expect(
        factory.connect(user1).registerUser("NewUsername", "NewBio")
      ).to.be.revertedWithCustomError(factory, "AlreadyRegistered");
    });

    it("Should not allow re-registration with same data", async function () {
      await factory.connect(user1).registerUser(username, bio);
      
      await expect(
        factory.connect(user1).registerUser(username, bio)
      ).to.be.revertedWithCustomError(factory, "AlreadyRegistered");
    });

    it("Should allow different users to use same username", async function () {
      await factory.connect(user1).registerUser(username, "Bio1");
      await expect(factory.connect(user2).registerUser(username, "Bio2"))
        .to.emit(factory, "UserRegistered");
    });
  });

  describe("View Functions", function () {
    const username = "Alice";
    const bio = "DeFi enthusiast";

    beforeEach(async function () {
      await factory.connect(user1).registerUser(username, bio);
    });

    describe("isUserRegistered", function () {
      it("Should return true for registered user", async function () {
        expect(await factory.isUserRegistered(user1.address)).to.be.true;
      });

      it("Should return false for unregistered user", async function () {
        expect(await factory.isUserRegistered(user2.address)).to.be.false;
      });
    });

    describe("getUserInfo", function () {
      it("Should return correct user info", async function () {
        const [returnedUsername, returnedBio, timestamp] = await factory.getUserInfo(user1.address);
        
        expect(returnedUsername).to.equal(username);
        expect(returnedBio).to.equal(bio);
        expect(timestamp).to.be.gt(0);
      });

      it("Should revert for unregistered user", async function () {
        await expect(
          factory.getUserInfo(user2.address)
        ).to.be.revertedWithCustomError(factory, "NotRegistered");
      });
    });

    describe("getUsername", function () {
      it("Should return correct username", async function () {
        expect(await factory.getUsername(user1.address)).to.equal(username);
      });

      it("Should revert for unregistered user", async function () {
        await expect(
          factory.getUsername(user2.address)
        ).to.be.revertedWithCustomError(factory, "NotRegistered");
      });
    });

    describe("getBio", function () {
      it("Should return correct bio", async function () {
        expect(await factory.getBio(user1.address)).to.equal(bio);
      });

      it("Should revert for unregistered user", async function () {
        await expect(
          factory.getBio(user2.address)
        ).to.be.revertedWithCustomError(factory, "NotRegistered");
      });
    });

    describe("getRegistrationTimestamp", function () {
      it("Should return valid timestamp", async function () {
        const timestamp = await factory.getRegistrationTimestamp(user1.address);
        expect(timestamp).to.be.gt(0);
      });

      it("Should revert for unregistered user", async function () {
        await expect(
          factory.getRegistrationTimestamp(user2.address)
        ).to.be.revertedWithCustomError(factory, "NotRegistered");
      });
    });
  });

  describe("Events", function () {
    it("Should emit UserRegistered event with correct parameters", async function () {
      const username = "Alice";
      const bio = "DeFi enthusiast";
      
      const tx = await factory.connect(user1).registerUser(username, bio);
      const receipt = await tx.wait();
      const block = await ethers.provider.getBlock(receipt!.blockNumber);

      await expect(tx)
        .to.emit(factory, "UserRegistered")
        .withArgs(user1.address, username, block!.timestamp);
    });

    it("Should emit event for each registration", async function () {
      await expect(factory.connect(user1).registerUser("Alice", "Bio1"))
        .to.emit(factory, "UserRegistered");
      
      await expect(factory.connect(user2).registerUser("Bob", "Bio2"))
        .to.emit(factory, "UserRegistered");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle very long valid username (20 chars)", async function () {
      const longUsername = "a".repeat(20);
      await expect(factory.connect(user1).registerUser(longUsername, "Bio"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle very long valid bio (30 chars)", async function () {
      const longBio = "b".repeat(30);
      await expect(factory.connect(user1).registerUser("Alice", longBio))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle registration with whitespace in username", async function () {
      await expect(factory.connect(user1).registerUser("Alice Smith", "Bio"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle registration with whitespace in bio", async function () {
      await expect(factory.connect(user1).registerUser("Alice", "DeFi enthusiast"))
        .to.emit(factory, "UserRegistered");
    });

    it("Should handle multiple registrations in same block", async function () {
      // This tests that timestamps are correctly set even for same-block registrations
      await factory.connect(user1).registerUser("Alice", "Bio1");
      await factory.connect(user2).registerUser("Bob", "Bio2");

      const timestamp1 = await factory.getRegistrationTimestamp(user1.address);
      const timestamp2 = await factory.getRegistrationTimestamp(user2.address);

      expect(timestamp1).to.be.gt(0);
      expect(timestamp2).to.be.gt(0);
    });
  });

  describe("Gas Optimization", function () {
    it("Should use custom errors for gas efficiency", async function () {
      // Custom errors are more gas efficient than require strings
      // This test verifies they are being used
      await factory.connect(user1).registerUser("Alice", "Bio");
      
      try {
        await factory.connect(user1).registerUser("Bob", "Bio2");
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("AlreadyRegistered");
      }
    });
  });
  describe("Vault Creation", function () {
    let mockAsset: MockERC20;
    let mockPriceFeed: ChainlinkMock;

    beforeEach(async function () {
      // Deploy Mock Token
      const MockERC20Factory = await ethers.getContractFactory("MockERC20");
      mockAsset = (await MockERC20Factory.deploy("Mock Token", "MTK", 18)) as unknown as MockERC20;
      await mockAsset.waitForDeployment();

      // Deploy Mock Price Feed
      const ChainlinkMockFactory = await ethers.getContractFactory("ChainlinkMock");
      mockPriceFeed = (await ChainlinkMockFactory.deploy(200000000000, 8)) as unknown as ChainlinkMock; // $2000
      await mockPriceFeed.waitForDeployment();

      // Register user1
      await factory.connect(user1).registerUser("Alice", "Bio");
    });

    it("Should create vault successfully when price feed is set", async function () {
      // Set price feed
      await factory.connect(owner).setAssetPriceFeed(await mockAsset.getAddress(), await mockPriceFeed.getAddress());

      // Create vault
      await expect(factory.connect(user1).createVault(await mockAsset.getAddress(), "Vault Token", "vtMTK"))
        .to.emit(factory, "VaultCreated")
        .withArgs(user1.address, anyValue, await mockAsset.getAddress(), anyValue);

      // Verify vault count
      expect(await factory.getTotalVaults()).to.equal(1);
      expect(await factory.getVaultCount(user1.address)).to.equal(1);
    });

    it("Should revert if user is not registered", async function () {
      // Set price feed
      await factory.connect(owner).setAssetPriceFeed(await mockAsset.getAddress(), await mockPriceFeed.getAddress());

      await expect(
        factory.connect(user2).createVault(await mockAsset.getAddress(), "Vault Token", "vtMTK")
      ).to.be.revertedWithCustomError(factory, "NotRegistered");
    });

    it("Should revert if price feed is not set", async function () {
      await expect(
        factory.connect(user1).createVault(await mockAsset.getAddress(), "Vault Token", "vtMTK")
      ).to.be.revertedWithCustomError(factory, "PriceFeedNotSet");
    });

    it("Should track created vaults correctly", async function () {
      await factory.connect(owner).setAssetPriceFeed(await mockAsset.getAddress(), await mockPriceFeed.getAddress());
      
      const tx = await factory.connect(user1).createVault(await mockAsset.getAddress(), "Vault Token", "vtMTK");
      const receipt = await tx.wait();
      
      // Get vault address from logs
      // The VaultCreated event is the last event emitted by the factory
      const event = (await factory.queryFilter(factory.filters.VaultCreated, receipt!.blockNumber)).pop();
      const vaultAddress = event!.args!.vault;

      // Verify mappings
      expect(await factory.getVaultOwner(vaultAddress)).to.equal(user1.address);
      const userVaults = await factory.getUserVaults(user1.address);
      expect(userVaults[0]).to.equal(vaultAddress);
      expect(await factory.getVaultCreationTime(vaultAddress)).to.be.gt(0);
    });

    it("Should allow user to create multiple vaults", async function () {
      await factory.connect(owner).setAssetPriceFeed(await mockAsset.getAddress(), await mockPriceFeed.getAddress());
      
      await factory.connect(user1).createVault(await mockAsset.getAddress(), "Vault 1", "v1");
      await factory.connect(user1).createVault(await mockAsset.getAddress(), "Vault 2", "v2");

      expect(await factory.getVaultCount(user1.address)).to.equal(2);
      const vaults = await factory.getUserVaults(user1.address);
      expect(vaults.length).to.equal(2);
      expect(vaults[0]).to.not.equal(vaults[1]);
    });
  });

  describe("Admin System", function () {
    let mockAsset: MockERC20;
    let mockPriceFeed: ChainlinkMock;

    beforeEach(async function () {
      // Deploy Mock Token
      const MockERC20Factory = await ethers.getContractFactory("MockERC20");
      mockAsset = (await MockERC20Factory.deploy("Mock Token", "MTK", 18)) as unknown as MockERC20;
      await mockAsset.waitForDeployment();

      // Deploy Mock Price Feed
      const ChainlinkMockFactory = await ethers.getContractFactory("ChainlinkMock");
      mockPriceFeed = (await ChainlinkMockFactory.deploy(200000000000, 8)) as unknown as ChainlinkMock; // $2000
      await mockPriceFeed.waitForDeployment();
    });

    it("Should set deployer as initial admin", async function () {
      expect(await factory.deployerAdmin()).to.equal(owner.address);
      expect(await factory.isAdmin(owner.address)).to.be.true;
      expect(await factory.getAdminCount()).to.equal(1);
    });

    it("Should allow admin to add new admin", async function () {
      await expect(factory.connect(owner).addAdmin(user1.address))
        .to.emit(factory, "AdminAdded")
        .withArgs(user1.address, owner.address);

      expect(await factory.isAdmin(user1.address)).to.be.true;
      expect(await factory.getAdminCount()).to.equal(2);
    });

    it("Should allow admin to remove admin", async function () {
      await factory.connect(owner).addAdmin(user1.address);
      
      await expect(factory.connect(owner).removeAdmin(user1.address))
        .to.emit(factory, "AdminRemoved")
        .withArgs(user1.address, owner.address);

      expect(await factory.isAdmin(user1.address)).to.be.false;
      expect(await factory.getAdminCount()).to.equal(1);
    });

    it("Should prevent duplicate admin addition", async function () {
      await factory.connect(owner).addAdmin(user1.address);
      
      await expect(
        factory.connect(owner).addAdmin(user1.address)
      ).to.be.revertedWithCustomError(factory, "AdminAlreadyExists");
    });

    it("Should prevent removing non-existent admin", async function () {
      await expect(
        factory.connect(owner).removeAdmin(user1.address)
      ).to.be.revertedWithCustomError(factory, "AdminDoesNotExist");
    });

    it("Should prevent removing deployer admin", async function () {
      await expect(
        factory.connect(owner).removeAdmin(owner.address)
      ).to.be.revertedWithCustomError(factory, "CannotRemoveDeployer");
    });

    it("Should restrict admin functions to admins only", async function () {
      await expect(
        factory.connect(user1).addAdmin(user2.address)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");

      await expect(
        factory.connect(user1).removeAdmin(owner.address)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");
    });

    it("Should allow new admin to manage other admins", async function () {
      await factory.connect(owner).addAdmin(user1.address);
      
      await expect(factory.connect(user1).addAdmin(user2.address))
        .to.emit(factory, "AdminAdded")
        .withArgs(user2.address, user1.address);
        
      expect(await factory.isAdmin(user2.address)).to.be.true;
    });

    it("Should restrict setAssetPriceFeed to admins", async function () {
      const mockAssetAddr = await mockAsset.getAddress();
      const mockFeedAddr = await mockPriceFeed.getAddress();

      await expect(
        factory.connect(user1).setAssetPriceFeed(mockAssetAddr, mockFeedAddr)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");

      await factory.connect(owner).addAdmin(user1.address);
      
      await expect(factory.connect(user1).setAssetPriceFeed(mockAssetAddr, mockFeedAddr))
        .to.emit(factory, "PriceFeedUpdated");
    });
  });

  describe("Protocol Address Management", function () {
    const mockAaveAddress = "0x1111111111111111111111111111111111111111";
    const mockCompoundAddress = "0x2222222222222222222222222222222222222222";
    const mockUniswapAddress = "0x3333333333333333333333333333333333333333";
    const mockWETHAddress = "0x4444444444444444444444444444444444444444";

    it("Should allow admin to set Aave address", async function () {
      await expect(factory.connect(owner).setAaveAddress(mockAaveAddress))
        .to.emit(factory, "ProtocolAddressSet")
        .withArgs("Aave", mockAaveAddress, owner.address);

      expect(await factory.getAaveAddress()).to.equal(mockAaveAddress);
    });

    it("Should allow admin to set Compound address", async function () {
      await expect(factory.connect(owner).setCompoundAddress(mockCompoundAddress))
        .to.emit(factory, "ProtocolAddressSet")
        .withArgs("Compound", mockCompoundAddress, owner.address);

      expect(await factory.getCompoundAddress()).to.equal(mockCompoundAddress);
    });

    it("Should allow admin to set Uniswap address", async function () {
      await expect(factory.connect(owner).setUniswapAddress(mockUniswapAddress))
        .to.emit(factory, "ProtocolAddressSet")
        .withArgs("Uniswap", mockUniswapAddress, owner.address);

      expect(await factory.getUniswapAddress()).to.equal(mockUniswapAddress);
    });

    it("Should allow admin to set WETH address", async function () {
      await expect(factory.connect(owner).setWETHAddress(mockWETHAddress))
        .to.emit(factory, "ProtocolAddressSet")
        .withArgs("WETH", mockWETHAddress, owner.address);

      expect(await factory.getWETHAddress()).to.equal(mockWETHAddress);
    });

    it("Should prevent non-admin from setting protocol addresses", async function () {
      await expect(
        factory.connect(user1).setAaveAddress(mockAaveAddress)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");

      await expect(
        factory.connect(user1).setCompoundAddress(mockCompoundAddress)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");

      await expect(
        factory.connect(user1).setUniswapAddress(mockUniswapAddress)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");

      await expect(
        factory.connect(user1).setWETHAddress(mockWETHAddress)
      ).to.be.revertedWithCustomError(factory, "NotAdmin");
    });

    it("Should prevent setting zero address for Aave", async function () {
      await expect(
        factory.connect(owner).setAaveAddress(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(factory, "ZeroAddress");
    });

    it("Should prevent setting zero address for Compound", async function () {
      await expect(
        factory.connect(owner).setCompoundAddress(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(factory, "ZeroAddress");
    });

    it("Should prevent setting zero address for Uniswap", async function () {
      await expect(
        factory.connect(owner).setUniswapAddress(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(factory, "ZeroAddress");
    });

    it("Should prevent setting zero address for WETH", async function () {
      await expect(
        factory.connect(owner).setWETHAddress(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(factory, "ZeroAddress");
    });

    it("Should return zero address initially for all protocols", async function () {
      expect(await factory.getAaveAddress()).to.equal(ethers.ZeroAddress);
      expect(await factory.getCompoundAddress()).to.equal(ethers.ZeroAddress);
      expect(await factory.getUniswapAddress()).to.equal(ethers.ZeroAddress);
      expect(await factory.getWETHAddress()).to.equal(ethers.ZeroAddress);
    });

    it("Should allow updating protocol addresses", async function () {
      // Set initial addresses
      await factory.connect(owner).setAaveAddress(mockAaveAddress);
      expect(await factory.getAaveAddress()).to.equal(mockAaveAddress);

      // Update to new address
      const newAddress = "0x5555555555555555555555555555555555555555";
      await expect(factory.connect(owner).setAaveAddress(newAddress))
        .to.emit(factory, "ProtocolAddressSet")
        .withArgs("Aave", newAddress, owner.address);

      expect(await factory.getAaveAddress()).to.equal(newAddress);
    });
  });
});
