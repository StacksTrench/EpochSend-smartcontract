# ForgeX: Vult

**Yield-Native Liquidity Hooks on Base** — a DeFi protocol that stacks two yield sources into one vault position, powered by an AI strategy engine.

1. **ERC-4626 vault yield** — deposits routed to Aave and Compound for lending interest
2. **Uniswap v4 swap fee yield** — VultHook intercepts swaps and donates accrued vault yield back to LPs

---

## Project Structure

```
forgeX/
├── smartcontract/          # Solidity smart contracts (Hardhat + Foundry)
│   ├── contracts/
│   │   ├── VaultFactory.sol      # User registration + vault deployment factory
│   │   ├── UserVault.sol         # ERC-4626 compliant tokenized vault
│   │   ├── vult/VultHook.sol     # Uniswap v4 hook for yield harvesting
│   │   └── interfaces/           # Protocol interfaces (Aave, Compound, ERC-4626)
│   ├── test/                     # Hardhat + Foundry tests
│   └── README.md
│
├── frontend/               # Next.js 16 frontend
│   ├── app/                # App Router pages (8 routes)
│   ├── components/         # React components
│   ├── hooks/              # Custom wagmi hooks
│   ├── lib/                # ABIs, constants, AI client
│   └── README.md
│
└── ai-backend/             # Python FastAPI + Claude AI
    ├── main.py             # 7 API endpoints
    ├── ai_engine.py        # Claude Sonnet integration
    ├── chain.py            # On-chain data via Web3.py
    └── README.md
```

---

## Deployed Contracts — Base Mainnet

| Contract | Address | Purpose |
|----------|---------|---------|
| VaultFactory | [`0x8374257da04F00ABAf74E13EFE5A17B0f08EC226`](https://basescan.org/address/0x8374257da04F00ABAf74E13EFE5A17B0f08EC226) | User registration + vault deployment |
| VultHook | [`0xe988b6816d94C10377779F08f2ab08925cE96D09`](https://basescan.org/address/0xe988b6816d94C10377779F08f2ab08925cE96D09) | Uniswap v4 yield harvesting hook |
| Base PoolManager | [`0x498581Ff718922c3f8e6A2444956aF099B2652b2`](https://basescan.org/address/0x498581Ff718922c3f8e6A2444956aF099B2652b2) | Uniswap v4 reference |

---

## Tech Stack

### Smart Contracts
- **Language:** Solidity ^0.8.20 / ^0.8.24
- **Frameworks:** Hardhat + Foundry
- **Network:** Base Mainnet (Chain ID 8453)
- **Standards:** ERC-4626, ERC-20, Uniswap v4 IHooks
- **Integrations:** Aave V3, Compound V2, Chainlink Price Feeds

### Frontend
- **Framework:** Next.js 16.1.1 (App Router)
- **Language:** TypeScript
- **Styling:** Tailwind CSS v4
- **Web3:** Wagmi v3, Viem v2, Reown AppKit
- **Animations:** Framer Motion
- **Deployed:** Vercel

### AI Backend
- **Framework:** FastAPI (Python 3.11)
- **AI:** Anthropic Claude (claude-sonnet-4)
- **On-chain reads:** Web3.py
- **Deployed:** Render — `https://forgex-14vp.onrender.com`

---

## Features

### Smart Contracts
- Multi-vault creation per user (unlimited)
- User registration system (username, bio, timestamp)
- ERC-4626 standard — deposit/withdraw/mint/redeem with share accounting
- Aave V3 and Compound V2 protocol integration for lending yield
- Chainlink Price Feeds for real-time USD valuations
- VultHook: `afterAddLiquidity` deploys idle LP liquidity into vaults; `afterSwap` harvests accrued yield and donates back to LPs
- Pause/unpause emergency controls
- Owner-based governance with `transferOwnership`

### Frontend (8 Pages)
- **Landing** — marketing page, wallet connect, registration flow
- **Dashboard** — vault grid, AI insights panel (Insights / Strategy / Risk tabs), user profile
- **Vaults** — full vault management with Deposit / Withdraw / Allocate / Share / Admin actions
- **Analytics** — per-vault yield %, USD value, share price, Aave/Compound/Idle allocation bar
- **Portfolio** — aggregated view: total USD, combined yield %, portfolio-wide allocation bar, per-vault table
- **Compare** — side-by-side vault comparison grid (all metrics, all vaults)
- **History** — on-chain Deposit/Withdraw event log via `getLogs`, linked to BaseScan
- **VultHook** — hook contract addresses, 3-step explainer, hook flags, specs

### AI Backend (7 Endpoints)
- `GET /api/portfolio/{address}` — on-chain portfolio via Web3.py
- `POST /api/insights` — bullet-point dashboard insights
- `POST /api/strategy` — yield strategy advice (conservative/balanced/aggressive)
- `POST /api/risk` — risk score 1–10 + breakdown
- `POST /api/chat` — conversational assistant with history
- `GET /api/platform-stats` — protocol-wide statistics
- `GET /health` — health check

---

## Design System

ForgeX uses an **olive green** theme:

- **Primary:** `#8FA828` — main brand, CTAs, active states
- **Background:** `#090A06` — near-black dark base
- **Card:** `#181B0C` — elevated surfaces
- **Foreground:** `#E8E2CF` — warm off-white text
- **Light mode:** full warm palette togglable via ThemeToggle in navbar

---

## Quick Start

### Smart Contracts
```bash
cd smartcontract
npm install
npx hardhat compile
npx hardhat test
```

### Frontend
```bash
cd frontend
npm install
# create .env.local (see Environment Variables)
npm run dev
```

### AI Backend
```bash
cd ai-backend
pip install -r requirements.txt
# create .env (see Environment Variables)
uvicorn main:app --reload
```

---

## Environment Variables

### Frontend (`.env.local`)
```env
NEXT_PUBLIC_REOWN_PROJECT_ID=your_reown_project_id
NEXT_PUBLIC_AI_BACKEND_URL=https://forgex-14vp.onrender.com
```

### Smart Contracts (`.env`)
```env
PRIVATE_KEY=your_private_key
BASE_RPC_URL=https://mainnet.base.org
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### AI Backend (`.env`)
```env
ANTHROPIC_API_KEY=sk-ant-...
BASE_RPC_URL=https://mainnet.base.org
VAULT_FACTORY_ADDRESS=0x8374257da04F00ABAf74E13EFE5A17B0f08EC226
```

---

## How Yield Stacking Works

```
LP adds liquidity → VultHook deposits into ForgeX vault → Vault deploys to Aave/Compound
                                                                ↓
LP gets swap fees ← VultHook donates yield back ← Vault earns lending interest
```

User vaults and hook vaults are separate: users deposit into personal `UserVault` instances and manually allocate to Aave/Compound. VultHook operates at the Uniswap pool level automatically — no user action needed on that side.

---

## Network Configuration

- **Primary:** Base Mainnet — Chain ID 8453 — [BaseScan](https://basescan.org/)
- **Testnet:** Base Sepolia — Chain ID 84532

---

## Repository

[https://github.com/BitBand-Labs/forgeX](https://github.com/BitBand-Labs/forgeX)

## License

MIT License
