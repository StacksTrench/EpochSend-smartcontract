# EpochSend — Smart Contracts

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
</p>

---

## 🧠 What is this contract?

Stellar's Soroban smart contracts are incredibly fast, but they can't make HTTP requests to the outside world. This repository contains the core contract that bridges that gap. 

EpochSend locks funds in escrow and assigns them to a specific `oracle_id`. When a Web2 event occurs (e.g. shipping confirmation, Stripe payment, database update), our Express oracle service listens to it, signs a release transaction, and calls `execute_intent` on the contract. 

It keeps the escrow logic entirely on-chain while letting real-world APIs control the release.

---

## 🎯 The Problem

Conditional transactions are normally slow, manual, and expensive. Either the buyer has to trust the seller, or they pay high fees to centralized escrow brokers. EpochSend solves this by replacing manual middlemen with code. Senders define the rules, funds lock securely, and the contract manages the release.

---

## 🏗️ Architecture

```
User (Freighter Wallet)
        │
        │  create_intent(recipient, asset, amount, expiration, oracle_id)
        ▼
EpochSend Soroban Contract (Status: Pending)
        │
        ├── Locks tokens in contract escrow
        │
        ├── Wait for Web2 Oracle Trigger
        │   └── Express Oracle service verifies event & signs tx
        ▼
execute_intent() ────► Transfer to Recipient ✅
(or refund_intent() if timeout reached) 🔄
```

---

## 🧩 Contract Features

| Feature | Function | Status |
|---|---|---|
| Contract initialization | `initialize(env, admin)` | ✅ Implemented |
| Admin WASM upgrade | `upgrade(env, new_wasm_hash)` | ✅ Implemented |
| Fund locking / intent creation | `create_intent(...)` | ✅ Implemented |
| Intent state query | `get_intent(intent_id)` | ✅ Implemented |
| Oracle-triggered release | `execute_intent(intent_id)` | ✅ Implemented & Tested |
| Sender refund after expiry | `refund_intent(intent_id)` | ✅ Implemented & Tested |
| Expiration time-checks | ledger timestamp checks | ✅ Implemented & Tested |

---

## 🛠️ Tech Stack

- **Language:** Rust (stable)
- **Smart Contract Engine:** Soroban SDK (v20+)
- **Testing:** `soroban-sdk` testutils + Rust unit tests
- **Deploy Tool:** `soroban-cli`

---

## 📁 Project Structure

```
EpochSend-smartcontract/
├── docs/
│   ├── PRD.md                  # Product Requirements Document
│   └── SMARTCONTRACT_GUIDE.md  # Soroban integration & deployment guide
│
├── smartcontract/              # Rust/Soroban project root
│   ├── src/
│   │   ├── lib.rs              # Main contract — EpochSendContract
│   │   └── test.rs             # Unit tests
│   ├── Cargo.toml              # Rust dependencies & WASM profile
│   └── Cargo.lock              # Pinned dependencies
│
├── README.md                   # This file
├── CONTRIBUTING.md             # Contribution guidelines
├── CODE_OF_CONDUCT.md          # Community standards
├── MAINTAINERS.md              # Project maintainers
└── STYLE.md                    # Rust code style guide
```

---

## 🚀 Getting Started

### Prerequisites
* Rust toolchain ([install](https://rustup.rs/))
* target `wasm32-unknown-unknown` (`rustup target add wasm32-unknown-unknown`)
* Soroban CLI (`cargo install --locked soroban-cli`)

### 1. Build the Contract
```bash
cd smartcontract
cargo build --target wasm32-unknown-unknown --release
```

### 2. Run Tests
```bash
cargo test
```
This runs our test suite, verifying intent creation, oracle execution, and refund timeouts.
