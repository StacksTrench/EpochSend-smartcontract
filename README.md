# PayWhen — Intent-Based Payment Protocol on Stellar

<div align="center">

![PayWhen](https://img.shields.io/badge/PayWhen-Protocol-8FA828?style=for-the-badge&logo=stellar&logoColor=white)

[![Network](https://img.shields.io/badge/Stellar-Network-7d32a8?style=flat-square&logo=stellar)](https://stellar.org)
[![Soroban](https://img.shields.io/badge/Soroban-Smart%20Contracts-FFD700?style=flat-square&logo=rust)](https://soroban.stellar.org)
[![Next.js](https://img.shields.io/badge/Next.js-15-000000?style=flat-square&logo=nextdotjs)](https://nextjs.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

**[Live Miniapp](https://paywhen.vercel.app) · [GitHub](https://github.com/BitBand-Labs/PayWhen)**

</div>

---

> **The Problem:** Payments today are manual, trust-based, and non-conditional. Users rely on verbal agreements, manual follow-ups, and third-party intermediaries — creating friction, disputes, and inefficiency.
>
> **The Solution:** PayWhen is an intent-based payment protocol on **Stellar** that allows users to define conditions under which funds are automatically executed on-chain. Instead of sending money immediately, users define rules — and the protocol enforces them using **Soroban smart contracts**.

---

## 🎯 Overview

PayWhen transforms **user intent** into **enforceable on-chain payment logic** on Stellar:

- “Send when delivery is confirmed”
- “Pay every Friday”
- “Release funds after milestone completion”

The system holds funds in escrow, monitors conditions, and executes automatically — no intermediaries, no manual intervention.

---

## 🧩 Core Features

### 1. Conditional Payment Contracts (Soroban)

- Create payments with custom conditions
- Funds locked securely in escrow
- Automatic execution when conditions are met
- Refund logic if conditions fail

### 2. Supported Conditions

**Time-based**

- Execute at specific timestamp
- Recurring payments (weekly/monthly)

**Manual Trigger**

- Recipient confirms delivery
- Multi-party approval flows

**Oracle-based** (Phase 2)

- GPS/location verification
- API-based external triggers via Soroban oracles

### 3. Payment Types

- One-time conditional payments
- Recurring subscriptions
- Group contributions (threshold unlock)

### 4. Escrow System

- Funds locked in Soroban smart contracts
- Timeout-based refunds
- Optional dispute resolution period
- Non-custodial — users always control their keys via Stellar wallets

---

## 🏗️ Architecture

| Layer               | Technology                    | Purpose                                         |
| ------------------- | ----------------------------- | ----------------------------------------------- |
| **Smart Contracts** | Soroban (Rust)                | Conditional payments, escrow, logic enforcement |
| **Frontend**        | Next.js, TypeScript, Tailwind | Mobile-first miniapp UI                         |
| **Network**         | Stellar (Futurenet/Testnet)   | Fast, low-cost asset transfers                  |

### Smart Contracts (Soroban)

#### `PaymentFactory`

- Creates new conditional payment contracts
- Tracks all active payments
- Manages payment lifecycle

#### `ConditionalPayment`

- Core escrow contract
- Stores sender, recipient, amount, condition logic
- Handles execution, refunds, and disputes

---

## 🎨 Frontend Miniapp

Lightweight, mobile-first interface:

- **Create Payment**: Set amount, recipient, condition type
- **View Status**: Active, pending, completed, refunded
- **Trigger Execution**: Manual approval or auto-execute
- **Real-time Updates**: Live contract state via Stellar SDK

---

## 🔐 Security

- Reentrancy protection
- Escrow fund safety
- Condition validation (on-chain verification)
- Timeout fallback logic (automatic refunds)
- Auditable on-chain execution (full transparency)

---

## 🚀 Development

### Prerequisites

- Node.js 18+
- Rust & Cargo (for Soroban)
- Freighter Wallet

### Smart Contracts

```bash
cd smartcontract

# Build contracts
cargo build --target wasm32-unknown-unknown --release

# Run tests
cargo test
```

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Run dev server
npm run dev
```

---

## 📊 Success Metrics

- Number of payments created
- Total transaction volume (USDC/XLM)
- Unique users
- Execution success rate
- Average time-to-execution

---

## 🗺️ Roadmap

### Phase 1 (MVP)

- Time-based payments
- Manual trigger
- Simple miniapp UI on Stellar
- Basic escrow with refunds

### Phase 2

- Oracle integrations
- Recurring payments
- Email/SMS notifications
- Multi-signature approvals

### Phase 3

- SDK for developers
- API integrations (Zapier, IFTTT)
- Cross-app triggers
- Mobile app (Stellar Wallet integration)

---

## 🔗 Links

- [Live Miniapp](https://paywhen.vercel.app/)
- [GitHub Repository](https://github.com/BitBand-Labs/PayWhen)

---

### 🤝 Contributing

Pull requests welcome! Please ensure:

- All tests pass
- Code follows existing style
- New features include tests
- Security best practices followed

### 📄 License

MIT © PayWhen Protocol
