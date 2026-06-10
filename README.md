# EpochSend — Smart Contracts

<p align="center">
  <img src="./docs/epochsend-logo.png" alt="EpochSend Logo" width="120" />
</p>

<p align="center">
  <strong>The Soroban escrow engine that turns payment intent into trustless, on-chain execution on Stellar.</strong>
</p>

<p align="center">
  <a href="https://epochsend.vercel.app/" target="_blank">
    <img src="https://img.shields.io/badge/Live%20App-epochsend.vercel.app-brightgreen?style=for-the-badge&logo=vercel" alt="Live App" />
  </a>
  <img src="https://img.shields.io/badge/Built%20on-Stellar%20Soroban-6B21A8?style=for-the-badge&logo=stellar" alt="Stellar Soroban" />
  <img src="https://img.shields.io/badge/Language-Rust-orange?style=for-the-badge&logo=rust" alt="Rust" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License" />
  <img src="https://github.com/StacksTrench/EpochSend-smartcontract/actions/workflows/ci.yml/badge.svg" alt="CI Status" />
</p>

---

## 🧠 What This Repository Is

This repository contains the core **Soroban smart contracts** that power the EpochSend protocol — the on-chain engine responsible for locking, monitoring, and releasing funds according to user-defined conditions.

> *"Lock funds. Define conditions. Let the contract do the rest."*

EpochSend converts a payment intent (a defined rule like "release funds when delivery is confirmed" or "pay after a specific timestamp") into enforceable, trustless on-chain logic. No third-party custodian. No manual intervention. No trust required between parties.

---

## 🎯 The Problem This Solves

Every real-world payment carries a hidden condition:
- "I'll pay when the work is done."
- "Release escrow when shipment is confirmed."
- "Pay every Friday at 9am."

Today, humans enforce those conditions manually and rely on trust. If trust breaks, funds are lost. EpochSend replaces that trust with **verifiable, on-chain logic** — written in Rust, executed by Soroban, verified by the Stellar network.

---

## 🏗️ Architecture

```
User (Freighter Wallet)
        │
        │  create_intent(recipient, asset, amount, expiration, oracle_id)
        ▼
EpochSend Soroban Contract
        │
        │  Locks tokens in contract escrow
        │  Stores Intent { sender, recipient, asset, amount, expiration, oracle_id, status }
        │
        ├──── Status: Pending
        │
        │  Condition Monitoring
        │  ┌─────────────────────────────────────────┐
        │  │  Time-Based:  ledger.timestamp >= expiration  │
        │  │  Oracle:      oracle_id signs execute()       │
        │  │  Manual:      arbiter signs execute()         │
        │  └─────────────────────────────────────────┘
        │
        ├──── Condition Met  →  execute_intent()  →  Transfer to Recipient ✅
        │
        └──── Timeout / Dispute  →  refund_intent()  →  Return to Sender 🔄
```

---

## 🧩 Contract Features

### Phase 1 — MVP (Current)
| Feature | Function | Status |
|---|---|---|
| Contract initialisation | `initialize(env, admin)` | ✅ Implemented |
| Admin WASM upgrade | `upgrade(env, new_wasm_hash)` | ✅ Implemented |
| Fund locking / intent creation | `create_intent(...)` | ✅ Implemented |
| Intent state query | `get_intent(intent_id)` | ✅ Implemented |
| Oracle-triggered fund release | `execute_intent(intent_id)` | 🔨 In Progress |
| Sender refund after expiry | `refund_intent(intent_id)` | 🔨 In Progress |
| Expiration enforcement | timestamp check on execute/refund | 🔨 In Progress |
| Soroban event emission | `events().publish(...)` | ❌ Pending |
| Persistent storage TTL management | `extend_ttl(...)` | ❌ Pending |

### Phase 2 — Automation & Oracles
| Feature | Status |
|---|---|
| Cryptographic oracle signature verification | 🔜 Planned |
| Admin pause / circuit breaker | 🔜 Planned |
| Per-intent deposit caps | 🔜 Planned |
| Intent enumeration by sender | 🔜 Planned |

### Phase 3 — Production Hardening
| Feature | Status |
|---|---|
| Admin transfer / multi-sig governance | 🔜 Planned |
| Fuzz testing on math operations | 🔜 Planned |
| Soroban SDK upgrade to latest stable | 🔜 Planned |
| Stellar Expert deployment verification | 🔜 Planned |

---

## 🛠️ Tech Stack

| Category | Technology | Version |
|---|---|---|
| **Language** | Rust | stable |
| **Smart Contract Engine** | Soroban SDK | 20.0.0 |
| **Compile Target** | `wasm32-unknown-unknown` | — |
| **Blockchain** | Stellar Network | Testnet / Mainnet |
| **Testing** | `soroban-sdk` testutils + Rust `#[test]` | — |
| **CI** | GitHub Actions | — |
| **Deploy Tool** | `soroban-cli` | latest |

---

## 📁 Project Structure

```
EpochSend-smartcontract/
├── docs/
│   ├── ISSUES.md               # Granular smart contract task tracker & roadmap
│   ├── PRD.md                  # Product Requirements Document
│   └── SMARTCONTRACT_GUIDE.md  # Soroban integration & deployment guide
│
├── smartcontract/              # Rust/Soroban project root
│   ├── src/
│   │   ├── lib.rs              # Main contract — EpochSendContract
│   │   └── test.rs             # Unit tests
│   ├── Cargo.toml              # Rust dependencies & WASM profile
│   ├── Cargo.lock              # Pinned dependency versions
│   └── .env.example            # Deployment env vars template
│
├── .github/
│   └── workflows/ci.yml        # GitHub Actions: build WASM + run tests
│
├── .env.example                # Root-level environment variable template
├── .gitignore                  # Excludes target/, .env files, test snapshots
├── README.md                   # This file
├── CONTRIBUTING.md             # Contribution guidelines
├── CODE_OF_CONDUCT.md          # Community standards
├── MAINTAINERS.md              # Project maintainers
└── STYLE.md                    # Rust code style guide
```

---

## 🚀 Getting Started

### Prerequisites

- **Rust** toolchain — [install via rustup](https://rustup.rs/)
- **Soroban CLI** — `cargo install --locked soroban-cli`
- **WASM target** — `rustup target add wasm32-unknown-unknown`
- A Stellar **Testnet** account — fund via [Friendbot](https://laboratory.stellar.org/#account-creator?network=test)

### 1. Clone & Navigate

```bash
git clone https://github.com/StacksTrench/EpochSend-smartcontract.git
cd EpochSend-smartcontract/smartcontract
```

### 2. Configure Environment

```bash
cp ../.env.example .env
```

Edit `.env`:

```env
# Stellar Network
SOROBAN_NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
SOROBAN_RPC_URL="https://soroban-testnet.stellar.org:443"

# Admin account (deploy wallet)
ADMIN_SECRET_KEY="S..."
ADMIN_PUBLIC_KEY="G..."

# Oracle / Arbiter accounts
ORACLE_SECRET_KEY="S..."
ARBITER_SECRET_KEY="S..."
```

> ⚠️ **Never commit real secret keys.** `.env` is gitignored. Use `.env.example` as the template only.

### 3. Build

```bash
# Compile to WASM binary
cargo build --target wasm32-unknown-unknown --release
```

The compiled WASM will be at:
```
target/wasm32-unknown-unknown/release/epochsend_contract.wasm
```

### 4. Run Tests

```bash
cargo test
```

Expected output:
```
running 1 test
test test::test_create_intent ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured
```

### 5. Deploy to Testnet

```bash
# Deploy the WASM binary
soroban contract deploy \
  --wasm target/wasm32-unknown-unknown/release/epochsend_contract.wasm \
  --source $ADMIN_SECRET_KEY \
  --network testnet

# Initialize the contract with your admin address
soroban contract invoke \
  --id <CONTRACT_ID> \
  --source $ADMIN_SECRET_KEY \
  --network testnet \
  -- initialize \
  --admin $ADMIN_PUBLIC_KEY
```

---

## 📖 Contract Interface

### `initialize(env, admin: Address)`
Sets the admin address and initialises the intent counter. Can only be called once. Panics if already initialised.

### `upgrade(env, new_wasm_hash: BytesN<32>)`
Admin-only. Upgrades the contract WASM binary in-place without migrating storage.

### `create_intent(env, sender, recipient, asset, amount, expiration, oracle_id) → u64`
Creates a new payment intent. Transfers `amount` tokens from `sender` to the contract. Returns the assigned `intent_id`.

| Parameter | Type | Description |
|---|---|---|
| `sender` | `Address` | Wallet locking the funds (must sign) |
| `recipient` | `Address` | Destination wallet |
| `asset` | `Address` | SAC token address (USDC, XLM, etc.) |
| `amount` | `i128` | Amount to lock (must be > 0) |
| `expiration` | `u64` | Unix timestamp after which a refund is valid |
| `oracle_id` | `Address` | Address authorised to trigger execution |

### `get_intent(env, intent_id: u64) → Option<Intent>`
Read-only. Returns the full `Intent` struct for a given ID, or `None` if not found.

---

## 🔐 Security Model

| Property | Implementation |
|---|---|
| **Non-custodial** | EpochSend developers have zero access to locked funds |
| **Sender auth** | `sender.require_auth()` enforced on `create_intent` |
| **Admin auth** | `admin.require_auth()` enforced on `upgrade` |
| **Amount validation** | Panics if `amount <= 0` |
| **Duplicate prevention** | `initialize` panics if already initialised |
| **No permanent lock** | Planned: `refund_intent` allows recovery after `expiration` |

---

## 🧪 Testing

All tests live in `smartcontract/src/test.rs` and use the Soroban testutils harness (`mock_all_auths()`, `register_stellar_asset_contract()`).

```bash
# Run all tests
cargo test

# Run a specific test
cargo test test_create_intent

# Run with output (useful for debugging)
cargo test -- --nocapture
```

See [`docs/ISSUES.md`](./docs/ISSUES.md) for the full testing roadmap — edge cases, fuzz tests, and integration scenarios.

---

## ⚙️ CI Pipeline

Every push and pull request to `main` triggers the GitHub Actions workflow at [`.github/workflows/ci.yml`](./.github/workflows/ci.yml):

1. Checkout repository
2. Install stable Rust toolchain with `wasm32-unknown-unknown` target
3. `cargo build --target wasm32-unknown-unknown --release` — verifies WASM compilation
4. `cargo test` — runs all unit tests

---

## 📊 Success Metrics

| Metric | Description |
|---|---|
| **Total Value Locked (TVL)** | Sum of all asset amounts in Pending intents |
| **Execution Rate** | Percentage of intents reaching Executed status vs Refunded |
| **Test Coverage** | Target: 100% of public contract functions covered |
| **Oracle Latency** | Time between condition being met and `execute_intent` confirmed |
| **Gas Efficiency** | Average XLM fee per `create_intent` / `execute_intent` operation |

---

## 📚 Documentation

| Document | Description |
|---|---|
| [📄 PRD](./docs/PRD.md) | Product vision, user flows, architecture, roadmap |
| [🗂️ Issues & Roadmap](./docs/ISSUES.md) | Granular smart contract task tracker (30 issues across 5 modules) |
| [🌐 Smart Contract Guide](./docs/SMARTCONTRACT_GUIDE.md) | Soroban integration, deployment, and XDR encoding reference |
| [🤝 Contributing](./CONTRIBUTING.md) | How to contribute to the contract codebase |
| [🎨 Style Guide](./STYLE.md) | Rust code style, naming conventions, and formatting |
| [📜 Code of Conduct](./CODE_OF_CONDUCT.md) | Community standards and expectations |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/sc-your-feature`
3. Make your changes — ensure `cargo test` passes and `cargo build --target wasm32-unknown-unknown --release` succeeds
4. Open a Pull Request against `main`

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) and [STYLE.md](./STYLE.md) before opening a PR.

---

## 👥 Maintainers

See [MAINTAINERS.md](./MAINTAINERS.md) for the full maintainer list.

---

## 📄 License

[MIT](./LICENSE) — free to use, fork, and build upon.

---

<p align="center">
  Built in Rust on <a href="https://stellar.org">Stellar Soroban</a> · Protocol UI at <a href="https://epochsend.vercel.app">epochsend.vercel.app</a>
</p>
