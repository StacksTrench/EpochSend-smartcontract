# ForgeX: Vult — Smart Contracts

Solidity smart contracts for the ForgeX yield-native DeFi protocol. Deployed on Base Mainnet.

---

## Deployed Contracts

| Contract | Address | Network |
|----------|---------|---------|
| VaultFactory | [`0x8374257da04F00ABAf74E13EFE5A17B0f08EC226`](https://basescan.org/address/0x8374257da04F00ABAf74E13EFE5A17B0f08EC226) | Base Mainnet |
| VultHook | [`0xe988b6816d94C10377779F08f2ab08925cE96D09`](https://basescan.org/address/0xe988b6816d94C10377779F08f2ab08925cE96D09) | Base Mainnet |
| Base PoolManager | [`0x498581Ff718922c3f8e6A2444956aF099B2652b2`](https://basescan.org/address/0x498581Ff718922c3f8e6A2444956aF099B2652b2) | Base Mainnet |

---

## Tech Stack

- **Language:** Solidity ^0.8.20 / ^0.8.24
- **Frameworks:** Hardhat (primary) + Foundry
- **Testing:** Hardhat + Chai (TypeScript), Forge (Solidity)
- **Network:** Base Mainnet — Chain ID 8453
- **Standards:** ERC-4626, ERC-20, Uniswap v4 `IHooks`
- **Dependencies:** OpenZeppelin v5, Uniswap v4-core/periphery, Chainlink

---

## Project Structure

```
smartcontract/
├── contracts/
│   ├── VaultFactory.sol          # User registration + vault factory
│   ├── UserVault.sol             # ERC-4626 tokenized vault
│   ├── vult/
│   │   └── VultHook.sol          # Uniswap v4 yield hook
│   ├── interfaces/
│   │   ├── IERC4626.sol
│   │   ├── IUserVault.sol
│   │   ├── IPool.sol             # Aave V3 interface
│   │   ├── IAToken.sol           # Aave aToken interface
│   │   └── ICToken.sol           # Compound cToken interface
│   └── mocks/                    # Test mocks (Aave, Compound, Chainlink, Uniswap)
├── test/
│   ├── UserVault.test.ts         # ~40 unit + integration tests
│   ├── VaultFactory.test.ts
│   ├── UserVault2.test.ts
│   ├── IERC4626.test.ts
│   ├── VultHook.test.ts
│   └── foundry/                  # Forge tests
├── scripts/
│   └── deploy.ts                 # Deployment scripts
├── hardhat.config.ts
├── foundry.toml
└── package.json
```

---

## Contract Architecture

### VaultFactory.sol

Central factory contract managing vault creation and user registration.

**Key Functions:**
- `registerUser(username, bio)` — register on-chain user profile
- `createVault(asset, name, symbol)` — deploy a new `UserVault` instance
- `getUserVaults(user)` — get all vaults for a user
- `getUserInfo(user)` — returns username, bio, registration timestamp
- `isUserRegistered(user)` — registration check
- `addAdmin(address)` / `removeAdmin(address)` — admin management

**Events:**
- `VaultCreated(address indexed owner, address indexed vault, address indexed asset, uint256 timestamp)`
- `UserRegistered(address indexed user, string username, uint256 timestamp)`

---

### UserVault.sol — ERC-4626 Tokenized Vault

**ERC-4626 Operations:**
- `deposit(assets, receiver)` — deposit assets, receive shares
- `withdraw(assets, receiver, owner)` — withdraw assets, burn shares
- `mint(shares, receiver)` — mint exact shares
- `redeem(shares, receiver, owner)` — redeem shares for assets
- `totalAssets()` — total managed assets
- `convertToShares(assets)` / `convertToAssets(shares)`

**Protocol Allocation:**
- `deployToAave(amount)` — send assets to Aave V3 lending pool
- `deployToCompound(amount)` — send assets to Compound cToken
- `withdrawFromAave(amount)` / `withdrawFromCompound(amount)` — recall from protocols

**Chainlink USD Valuations:**
- `getTotalValueUSD()` — total vault value in USD (18 decimals)
- `getSharePriceUSD()` — per-share USD price
- `getAssetPriceUSD()` — underlying asset spot price

**Protocol Balances:**
- `getAaveBalance()` — assets deployed to Aave
- `getCompoundBalance()` — assets deployed to Compound
- `totalAssetsAccrued()` — cumulative assets including accrued yield

**Admin:**
- `pause()` / `unpause()` — emergency controls
- `transferOwnership(newOwner)` — standard Ownable

---

### VultHook.sol — Uniswap v4 Hook

The key innovation. Sits between Uniswap v4 pools and ForgeX vaults. Operates automatically — no user action required.

**Active Flags:** `afterAddLiquidity`, `beforeSwap`, `afterSwap`

**Flow:**

```
afterAddLiquidity()  →  deposits idle pool liquidity into ForgeX vaults (Aave/Compound)
beforeSwap()         →  ensures pool has enough liquidity for the swap (rebalances if needed)
afterSwap()          →  compares totalAssetsAccrued vs totalAssets
                         if delta > 1000 wei → harvests yield
                         → poolManager.donate() → yield goes to LPs
```

**Result:** LPs earn both swap fees AND lending yield on their idle capital.

---

## Quick Start

### Hardhat

```bash
npm install
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.ts --network base
```

### Foundry

```bash
forge install
forge build
forge test
```

---

## Testing

```bash
# Hardhat tests (TypeScript)
npx hardhat test

# Specific file
npx hardhat test test/UserVault.test.ts

# With gas reporting
REPORT_GAS=true npx hardhat test

# Coverage
npx hardhat coverage

# Foundry tests
forge test -vvv
```

**Test Coverage:**
- `UserVault.test.ts` — ~40 tests covering deposit, withdraw, share math, protocol allocation, Chainlink feeds, pause/unpause
- `VaultFactory.test.ts` — registration, vault creation, admin roles
- `IERC4626.test.ts` — ERC-4626 compliance
- `VultHook.test.ts` — hook integration tests

---

## Environment Variables

Create a `.env` file (never commit):

```env
PRIVATE_KEY=your_private_key
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
```

---

## Network Configuration

| Network | Chain ID | RPC | Explorer |
|---------|----------|-----|----------|
| Base Mainnet | 8453 | `https://mainnet.base.org` | [basescan.org](https://basescan.org) |
| Base Sepolia | 84532 | `https://sepolia.base.org` | [sepolia.basescan.org](https://sepolia.basescan.org) |

---

## Security

- OpenZeppelin v5 base contracts (Ownable, ReentrancyGuard, Pausable)
- Reentrancy guards on all state-changing vault functions
- Admin role separation (owner vs. registered admins)
- Chainlink price feeds for manipulation-resistant USD values
- Pause mechanism for emergency stops
- ERC-4626 share math reviewed for inflation attack protection

**Note:** Contracts are deployed to Base Mainnet but have not undergone a formal third-party security audit.

---

## License

MIT License
