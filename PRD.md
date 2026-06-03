# 📘 Product Requirements Document (PRD)

## Product Name: EpochSend Smart Contracts

---

## 🧠 Overview

The **EpochSend Smart Contracts** form the decentralized foundation of the EpochSend protocol on the Stellar Network. 

While the frontend captures user intent and the backend listens to external APIs, the smart contract is the ultimate arbiter of truth. It locks funds safely on-chain and mathematically guarantees that those funds will only be released if the strictly defined conditions are met.

---

## 🎯 Problem Statement

Payments today are fundamentally flawed for complex transactions. Once money is sent, it's gone. If an agreement is broken, the sender has no recourse. Centralized escrow services solve this but charge massive fees and require blind trust.

To enable programmable, conditional payments without intermediaries, we need a robust smart contract that holds assets trustlessly and executes logic based on irrefutable cryptographic proofs.

---

## 💡 The EpochSend Solution

A suite of Soroban smart contracts written in Rust.

When a user creates a payment intent:
1. The `EscrowFactory` contract deploys or allocates a new escrow state.
2. Funds (USDC or XLM) are securely locked within the contract.
3. The contract registers the `Trigger Condition` (e.g., a specific timestamp, a required signature from the recipient, or an Oracle's cryptographic approval).
4. The contract acts passively until invoked to `execute` (releasing funds to the recipient) or `refund` (returning funds to the sender if the timeout is breached).

---

## 🧩 Core Features (MVP)

### 1. The Escrow State Machine
- Stores sender, recipient, asset type, amount, and the exact trigger condition.
- Protects against reentrancy attacks and double-spending.

### 2. Supported Cryptographic Conditions
**Phase 1: Time & Trust**
- **Time-based**: `execute` fails if the ledger timestamp is less than the unlock time.
- **Manual Trigger**: `execute` requires a cryptographic signature from a designated arbiter.

**Phase 2: Oracles**
- **Oracle Verification**: The contract accepts signatures from a designated server-side Oracle Wallet to prove that a real-world event (e.g., FedEx delivery) has occurred.

### 3. Automated Refunds (The Safety Net)
- Every escrow must have a `dispute_timeout`.
- If the trigger condition is never met, the sender can call `refund` to effortlessly retrieve their assets, ensuring funds are never permanently frozen.

---

## 🔐 Security Model

- **No Centralized Custody**: The contract code controls the assets. No developer or administrator can freeze or steal the funds.
- **Soroban Auth Framework**: Strict utilization of `require_auth()` to ensure only the authorized parties can trigger state changes.
- **Immutable Logic**: Once compiled to WASM and deployed, the core rules of execution cannot be covertly altered.

---

## 🚀 Roadmap

### Phase 1: MVP (Current)
- Basic `ConditionalPayment` contract.
- Time-based and Manual conditions.
- Factory pattern for deploying new escrows.

### Phase 2: Advanced Integrations
- Implementing the Oracle signature verification logic.
- Adding recurring payment smart contract templates.

### Phase 3: Multi-Sig & Arbitration
- N-of-M multi-signature approvals for high-value escrows.
- Decentralized arbitration fallback mechanisms.
