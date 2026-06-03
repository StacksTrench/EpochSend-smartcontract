# EpochSend - Smart Contracts

> **The On-Chain Escrow and Execution Logic for the EpochSend Protocol on Stellar.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built on Stellar](https://img.shields.io/badge/Built%20on-Stellar%20Soroban-purple)](https://soroban.stellar.org)

## 💡 Overview

This repository houses the core **Soroban smart contracts** that power the EpochSend protocol. 

EpochSend transforms user intent into enforceable on-chain payment logic. Rather than trusting a centralized third party, users lock their assets (USDC/XLM) inside these secure, immutable contracts. The contracts monitor predefined conditions (e.g., time locks, manual approvals, or Oracle webhooks) and strictly execute the payment to the recipient or refund the sender according to the agreed-upon rules.

---

## 🏗️ Architecture

```mermaid
graph TD
    User((User)) -->|Create Escrow| Vault[Soroban Conditional Contract]
    
    subgraph Execution Triggers
        Time[Time-based Unlock]
        Manual[Manual Authorization]
        Oracle[Oracle Webhook Trigger]
    end

    subgraph On-Chain State
        Vault -->|Monitors| Execution Triggers
    end
    
    Execution Triggers -->|Condition Met| Exec[Transfer to Recipient]
    Execution Triggers -->|Timeout Reached| Refund[Refund to Sender]
    
    Exec --> Recipient((Recipient))
    Refund --> User
```

---

## 🛠 Tech Stack

*   **Language:** Rust
*   **Blockchain:** Stellar Network
*   **Smart Contract Engine:** Soroban
*   **Logic:** Conditional escrow, asset transfers, cryptographic authorization.

---

## 🚀 Getting Started

### 1. Prerequisites
*   Rust toolchain
*   `soroban-cli` installed
*   Stellar Testnet account

### 2. Local Setup & Build

```bash
cd smartcontract

# Build the WASM binary
cargo build --target wasm32-unknown-unknown --release

# Run unit tests
cargo test
```

---

## 📚 Documentation & Task Tracking

*   🧠 **[Smart Contract Issues & Task Breakdown](./docs/ISSUES.md)**
*   📘 **[Smart Contract Technical Guide](./docs/SMARTCONTRACT_GUIDE.md)**
*   📄 **[Product Requirements Document](./docs/PRD.md)**

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [STYLE.md](STYLE.md).

---

*Project maintained by @babalola & contributors.*
