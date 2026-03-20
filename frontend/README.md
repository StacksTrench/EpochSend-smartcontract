# ForgeX: Vult — Frontend

Next.js 16 frontend for the ForgeX yield-native DeFi protocol on Base. Built with TypeScript, Tailwind CSS v4, Wagmi v3, and Reown AppKit.

---

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Next.js | 16.1.1 | App Router, SSR |
| React | 19.2.0 | UI |
| TypeScript | 5.x | Type safety |
| Tailwind CSS | v4 | Styling |
| Wagmi | v3 | Wallet hooks |
| Viem | v2 | On-chain reads/writes |
| Reown AppKit | latest | Wallet modal |
| Framer Motion | latest | Animations |
| Lucide React | latest | Icons |

---

## Design System

**Olive green** theme with warm neutrals:

| Token | Value | Usage |
|-------|-------|-------|
| `--primary` | `#8FA828` | CTAs, active nav, badges |
| `--background` | `#090A06` | Page background |
| `--card` | `#181B0C` | Card surfaces |
| `--foreground` | `#E8E2CF` | Body text |
| `--foreground-muted` | `#918E78` | Labels, secondary |

Full **light mode** supported via `data-theme="light"` on `<html>`, toggled by `ThemeToggle` in the navbar and persisted to `localStorage`.

---

## Pages (App Router)

| Route | Component | Description |
|-------|-----------|-------------|
| `/` | `app/page.tsx` | Landing — hero, stats, features, CTA |
| `/dashboard` | `app/dashboard/page.tsx` | Vault grid, AI insights, user profile |
| `/vaults` | `app/vaults/page.tsx` | Full vault management |
| `/analytics` | `app/analytics/page.tsx` | Per-vault yield %, USD value, allocation bar |
| `/portfolio` | `app/portfolio/page.tsx` | Aggregated portfolio view |
| `/compare` | `app/compare/page.tsx` | Side-by-side vault comparison grid |
| `/history` | `app/history/page.tsx` | On-chain Deposit/Withdraw event log |
| `/hook` | `app/hook/page.tsx` | VultHook info, addresses, how-it-works |

---

## Components

| Component | Description |
|-----------|-------------|
| `Navbar` | Logo, nav links (registered users only), ThemeToggle, LaunchButton, wallet button |
| `LaunchButton` | Connection status dot + "Launch App" CTA |
| `ThemeToggle` | Sun/Moon icon, toggles dark/light theme |
| `VaultCard` | Deposit / Withdraw / Allocate (Aave+Compound) / Share / Admin (owner only) |
| `CreateVaultModal` | Name, symbol, asset (WETH/USDC/DAI/USDT) selection |
| `RegisterForm` | Username + bio, calls `registerUser()` on-chain |
| `AIInsights` | Dashboard panel — Insights / Strategy / Risk tabs |
| `AIChat` | Floating bottom-left chat widget (Claude-powered) |
| `Toast` | Notifications — success / error / info / tx (with BaseScan link) |
| `HeroIllustration` | Landing page SVG illustration |
| `ClientLayout` | Wraps `<ToastProvider>`, `<Navbar>`, `<AIChat>` |

---

## Hooks

### `hooks/useVaultFactory.ts`
- `useIsRegistered()` — checks registration status
- `useUserVaults()` — returns array of vault addresses for connected user
- `useUserInfo()` — fetches username, bio, member-since from chain
- `useRegisterUser()` — calls `registerUser(username, bio)`
- `useCreateVault()` — calls `createVault(asset, name, symbol)`

### `hooks/useUserVault.ts`
- `useVaultData(address)` — multi-read: totalAssets, accrued, shares, USD values, Aave/Compound balances, paused state. All reads poll every **30 seconds** for real-time yield tracking.
- `useVaultDeposit(address)` — 2-step approve + deposit flow
- `useVaultWithdraw(address)` — withdraw assets
- `useDeployToAave(address)` / `useDeployToCompound(address)` — allocate to protocols
- `useWithdrawFromAave(address)` / `useWithdrawFromCompound(address)` — recall from protocols
- `useTransferShares(address)` — ERC-20 transfer of vault share tokens
- (inline) `useReadContract` for `owner()` + `useWriteContract` for `transferOwnership()` in VaultCard

---

## Project Structure

```
frontend/
├── app/
│   ├── layout.tsx            # Root layout (Web3Provider + ClientLayout)
│   ├── globals.css           # Design tokens, dark + light themes, utilities
│   ├── page.tsx              # Landing page
│   ├── dashboard/page.tsx
│   ├── vaults/page.tsx
│   ├── analytics/page.tsx
│   ├── portfolio/page.tsx
│   ├── compare/page.tsx
│   ├── history/page.tsx
│   └── hook/page.tsx
├── components/               # 11 React components
├── context/
│   └── Web3Provider.tsx      # createAppKit (unconditional, ssr: true) + WagmiProvider
├── config/
│   └── wagmi.ts              # projectId + networks export
├── hooks/
│   ├── useVaultFactory.ts
│   └── useUserVault.ts
├── lib/
│   ├── abis.ts               # VAULT_FACTORY_ABI, USER_VAULT_ABI, ERC20_ABI
│   ├── constants.ts          # Contract addresses, token addresses, AI_BACKEND_URL
│   └── ai.ts                 # Fetch helpers for AI backend endpoints
└── public/
    ├── logo.svg
    └── favicon.svg
```

---

## Environment Variables

Create a `.env.local` file (never commit this):

```env
# Required — get from https://cloud.reown.com
NEXT_PUBLIC_REOWN_PROJECT_ID=your_reown_project_id

# AI Backend (deployed on Render)
NEXT_PUBLIC_AI_BACKEND_URL=https://forgex-14vp.onrender.com
```

---

## Quick Start

```bash
npm install
# create .env.local with vars above
npm run dev        # http://localhost:3000
npm run build      # production build
npm run lint       # ESLint
```

---

## Wallet Connection

- **Provider:** Reown AppKit with `createAppKit()` called unconditionally at module level in `Web3Provider.tsx`
- **WagmiAdapter:** `ssr: true`
- **Networks:** Base Mainnet + Base Sepolia
- `<appkit-button />` and `<appkit-network-button />` web components used for wallet/network UI

---

## Network

- **Primary:** Base Mainnet — Chain ID 8453
- **Testnet:** Base Sepolia — Chain ID 84532
- **Explorer:** [BaseScan](https://basescan.org/)

---

## Deployed

Frontend is deployed on **Vercel**. Set Root Directory to `frontend` in Vercel dashboard settings.
