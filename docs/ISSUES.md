# EpochSend Soroban Smart Contract Issues & Roadmap

This document tracks the active development phases for the EpochSend Soroban smart contracts, defining the transition from concept to a secure, Stellar-native escrow protocol.

## 🔴 Phase 1: Core Escrow Implementation

### Issue #1: Initialize Soroban Project & State Management
**Status:** ❌ PENDING | **Priority:** CRITICAL
- **Description:** Set up the foundational Soroban environment in Rust.
- **Tasks:**
  - Define the `Intent` struct (sender, recipient, asset, amount, expiration, oracle_id, status).
  - Implement secure state storage for tracking intents by ID.
  - Add basic `initialize` and `upgrade` administrative functions.

### Issue #2: Asset Locking Mechanism
**Status:** ❌ PENDING | **Priority:** CRITICAL
- **Description:** Implement the function to lock Stellar native assets or SAC (Stellar Asset Contract) tokens.
- **Tasks:**
  - Implement the `create_intent` function.
  - Handle token transfers from the user's Freighter wallet to the contract's escrow address.
  - Ensure the contract properly records the locked balance and intent parameters.

## 🟡 Phase 2: Conditional Logic & Oracle Integration

### Issue #3: Oracle Authorization & Execution
**Status:** ❌ PENDING | **Priority:** HIGH
- **Description:** The smart contract must verify authorization from the off-chain EpochSend Express backend before releasing funds.
- **Tasks:**
  - Implement an `execute_intent` function.
  - Require a valid cryptographic signature from the registered Oracle address.
  - Transfer funds to the recipient upon successful signature verification.

### Issue #4: Time-Locks & Automated Refunds
**Status:** ❌ PENDING | **Priority:** HIGH
- **Description:** Senders must be able to reclaim funds if the oracle condition is never met within the specified timeframe.
- **Tasks:**
  - Implement a `refund_intent` function.
  - Verify that the current ledger timestamp is greater than the intent's `expiration`.
  - Ensure funds are returned securely to the original sender and the intent state is marked "Refunded".

## 🟢 Phase 3: Testing & Auditing

### Issue #5: Comprehensive Unit & Integration Tests
**Status:** ❌ PENDING | **Priority:** MEDIUM
- **Description:** The protocol must have 100% test coverage before hitting Testnet.
- **Tasks:**
  - Write standard Rust unit tests for `create_intent`, `execute_intent`, and `refund_intent`.
  - Create edge-case tests (e.g., executing an expired intent, refunding an active intent, invalid oracle signatures).
  - Simulate Soroban auth testing for Freighter wallet transactions.
