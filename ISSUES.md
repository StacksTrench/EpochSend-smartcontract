# ForgeX: Vult — Issues & Roadmap

## ✅ Completed

### Issue #1: Chainlink Price Feeds
**Status:** ✅ COMPLETED
Real-time USD valuation in `UserVault.sol`. `getTotalValueUSD()`, `getSharePriceUSD()`, `getAssetPriceUSD()` using `AggregatorV3Interface`. Displayed in frontend dashboard and analytics.

### Issue #2: Chainlink Automation Hooks
**Status:** ✅ COMPLETED
`checkUpkeep` and `performUpkeep` implemented in `UserVault.sol` for automated rebalancing trigger logic.

### Issue #4: Olive Green Brand Identity (ForgeX: Vult)
**Status:** ✅ COMPLETED
Full rebrand from tri-tone to olive green (`#8FA828`) theme. Custom SVG logo, Framer Motion animations, dark-mode-first design system. Light mode added via `data-theme` toggle.

### Issue #5: Repository & Attribution Audit
**Status:** ✅ COMPLETED
Git history cleaned, contributor attribution verified.

### Issue #6: VultHook — Uniswap v4 Yield Harvesting (UHI8)
**Status:** ✅ COMPLETED
`VultHook.sol` deployed to Base Mainnet (`0xe988b6816d94C10377779F08f2ab08925cE96D09`).
- `afterAddLiquidity` — deposits idle LP liquidity into ForgeX vaults
- `beforeSwap` — ensures pool liquidity before swaps
- `afterSwap` — harvests accrued yield, donates to LPs via `poolManager.donate()`

### Issue #7: Multi-Asset Vault Support
**Status:** ✅ COMPLETED
Vaults support WETH, USDC, DAI, USDT. Token addresses in `frontend/lib/constants.ts`.

### Issue #8: Protocol Deployment UI
**Status:** ✅ COMPLETED
VaultCard: Deploy to Aave / Deploy to Compound / Withdraw from Aave / Withdraw from Compound.

### Issue #9: Dashboard User Profile
**Status:** ✅ COMPLETED
Profile card on dashboard with username, bio, member-since. Inline registration flow.

### Issue #10: AI Backend
**Status:** ✅ COMPLETED
FastAPI + Claude (claude-sonnet-4) backend deployed to Render (`https://forgex-14vp.onrender.com`). 7 endpoints: portfolio, insights, strategy, risk, chat, platform-stats, health.

### Issue #11: Vault Analytics Page
**Status:** ✅ COMPLETED
`/analytics` — yield %, USD value, share price, protocol allocation bar per vault.

### Issue #12: Portfolio Page
**Status:** ✅ COMPLETED
`/portfolio` — aggregate: total USD, combined yield, portfolio-wide allocation bar, per-vault table.

### Issue #13: Transaction History
**Status:** ✅ COMPLETED
`/history` — ERC-4626 Deposit/Withdraw events via `getLogs` (last 50k blocks). BaseScan links.

### Issue #14: VultHook UI Page
**Status:** ✅ COMPLETED
`/hook` — contract addresses (copyable), 3-step explainer, hook flags, specs.

### Issue #15: Vault Comparison Page
**Status:** ✅ COMPLETED
`/compare` — side-by-side vault grid: assets, USD, yield %, Aave/Compound/idle, status.

### Issue #16: Enhanced Toast Notifications
**Status:** ✅ COMPLETED
Toast: success / error / info / `tx` types. `"tx"` type shows truncated txHash linked to BaseScan (6s duration).

### Issue #17: Vault Share Transfer
**Status:** ✅ COMPLETED
VaultCard "Share" button — ERC-20 share token transfer to any address.

### Issue #18: Dark/Light Theme Toggle
**Status:** ✅ COMPLETED
`ThemeToggle` in navbar. `data-theme` on `<html>`, localStorage persist. Full warm light palette.

### Issue #19: Real-Time Yield Tracking
**Status:** ✅ COMPLETED
All `useVaultData` reads use `refetchInterval: 30_000` — auto-refresh every 30 seconds.

### Issue #20: Vault Governance
**Status:** ✅ COMPLETED
VaultCard shows "Admin" button to vault owner. Transfer Ownership panel calls `transferOwnership()`.

---

## ❌ Pending / Future

### Issue #21: Frontend Test Suite
**Status:** ❌ PENDING
**Priority:** MEDIUM
No unit, integration, or E2E tests. Recommended: Vitest + Playwright.

### Issue #22: The Graph Subgraph
**Status:** ❌ PENDING
**Priority:** LOW
Index Deposit/Withdraw/VaultCreated/YieldHarvested events for full history, faster queries, and VultHook live harvest feed.

### Issue #23: VultHook Live Activity UI
**Status:** ❌ PENDING
**Priority:** LOW
Real-time yield harvest events from VultHook. Needs subgraph or websocket RPC + `useWatchContractEvent`.

### Issue #24: Chainlink Automation Registration
**Status:** ❌ PENDING
**Priority:** MEDIUM
`checkUpkeep`/`performUpkeep` are implemented in contracts but vault instances are not registered with Chainlink Automation network.

### Issue #25: Formal Security Audit
**Status:** ❌ PENDING
**Priority:** HIGH (for production)
Contracts deployed to Base Mainnet but no third-party audit completed.

### Issue #26: Mobile Polish
**Status:** ❌ PENDING
**Priority:** LOW
VaultCard action panels, comparison table, history table need tightening on small screens.
