# EpochSend Smart Contract — Issues & Roadmap 🛡️

**Live App:** [https://epochsend.vercel.app/](https://epochsend.vercel.app/)

This document is the authoritative engineering tracker for all Soroban smart contract development on the EpochSend protocol. It captures what has been built and verified, what is actively being worked on, and the complete roadmap to a production-grade, auditable Stellar-native escrow contract.

> **Standards:** Each issue carries — priority, labels, status, description, and granular task-level checkboxes grounded in the actual codebase.
> Status: ✅ COMPLETED | 🔨 IN PROGRESS | ❌ PENDING | 🔜 FUTURE

---

## 🏗️ Module 1: Foundation & State Management (SC-01 → SC-05)

### Issue #SC-01: Soroban Project Scaffold & Cargo Configuration
**Status:** ✅ COMPLETED | **Priority:** CRITICAL
**Labels:** `smart-contract`, `config`, `good-first-issue`
**Description:** Initialise the Rust/Soroban crate with correct dependencies, WASM build profile, and project metadata.
- **Tasks:**
  - [x] Initialise `epochsend-contract` crate with `crate-type = ["cdylib", "rlib"]`
  - [x] Add `soroban-sdk = "20.0.0"` dependency
  - [x] Add `soroban-sdk` with `testutils` feature as dev-dependency
  - [x] Configure WASM release profile: `opt-level = "z"`, `lto = true`, `strip = true`, `codegen-units = 1`
  - [x] Add `wasm32-unknown-unknown` as build target
  - [x] Pin `arbitrary` and `derive_arbitrary` to `1.3.2` to resolve `stellar-xdr` compilation conflict

---

### Issue #SC-02: DataKey & Storage Schema Definition
**Status:** ✅ COMPLETED | **Priority:** CRITICAL
**Labels:** `smart-contract`, `storage`, `architecture`
**Description:** Define the full storage key schema used to persist contract state across Soroban's instance and persistent storage tiers.
- **Tasks:**
  - [x] Define `DataKey` enum: `Admin`, `IntentCounter`, `Intent(u64)`
  - [x] Use instance storage for `Admin` and `IntentCounter` (cheap, frequently accessed)
  - [x] Use persistent storage for `Intent(u64)` (long-lived, keyed per intent)
  - [x] Derive `Clone`, `Copy`, `Debug`, `Eq`, `PartialEq` on `DataKey`
  - [ ] Add `DataKey::OracleRegistry` for a registered oracle address map (Phase 2)
  - [ ] Add `DataKey::Paused` for emergency pause flag (Phase 2)

---

### Issue #SC-03: Intent Struct & Status Enum
**Status:** ✅ COMPLETED | **Priority:** CRITICAL
**Labels:** `smart-contract`, `types`, `architecture`
**Description:** Define the core `Intent` data structure and `IntentStatus` lifecycle enum used throughout the contract.
- **Tasks:**
  - [x] Define `IntentStatus` enum: `Pending = 0`, `Executed = 1`, `Refunded = 2`
  - [x] Define `Intent` struct: `sender`, `recipient`, `asset`, `amount`, `expiration`, `oracle_id`, `status`
  - [x] Derive `Clone`, `Copy`, `Debug`, `Eq`, `PartialEq` on `IntentStatus`
  - [x] Apply `#[contracttype]` macro to both `DataKey` and `Intent` for Soroban XDR compatibility
  - [ ] Add `created_at: u64` field to `Intent` (ledger timestamp at creation) for auditability
  - [ ] Add `intent_label: Option<String>` for human-readable memo (Phase 2)

---

### Issue #SC-04: Contract Initialisation & Admin Setup
**Status:** ✅ COMPLETED | **Priority:** CRITICAL
**Labels:** `smart-contract`, `admin`, `security`
**Description:** Implement the one-time initialisation function that bootstraps contract state and assigns the admin authority.
- **Tasks:**
  - [x] Implement `initialize(env: Env, admin: Address)`
  - [x] Panic with "Already initialized" if `DataKey::Admin` exists in instance storage
  - [x] Store admin address in instance storage
  - [x] Initialise `IntentCounter` to `0u64`
  - [ ] Emit `Initialized { admin }` event on successful initialisation
  - [ ] Write unit test: re-initialisation should panic
  - [ ] Write unit test: counter starts at 0

---

### Issue #SC-05: Admin WASM Upgrade Function
**Status:** ✅ COMPLETED | **Priority:** HIGH
**Labels:** `smart-contract`, `admin`, `upgrade`
**Description:** Allow the admin to upgrade the contract WASM in-place without migrating storage, using Soroban's native upgrade mechanism.
- **Tasks:**
  - [x] Implement `upgrade(env: Env, new_wasm_hash: BytesN<32>)`
  - [x] Call `admin.require_auth()` to enforce admin-only access
  - [x] Call `env.deployer().update_current_contract_wasm(new_wasm_hash)` to perform the upgrade
  - [ ] Emit `ContractUpgraded { new_wasm_hash }` event
  - [ ] Write unit test: non-admin caller should be rejected by auth
  - [ ] Document upgrade procedure in `docs/SMARTCONTRACT_GUIDE.md`

---

## 🔒 Module 2: Core Escrow Logic (SC-06 → SC-13)

### Issue #SC-06: `create_intent` — Asset Locking Function
**Status:** ✅ COMPLETED | **Priority:** CRITICAL
**Labels:** `smart-contract`, `feature`, `escrow`
**Description:** The primary entry point. Accepts a payment intent definition, transfers tokens from the sender into the contract's escrow balance, and records the intent on-chain.
- **Tasks:**
  - [x] Implement `create_intent(env, sender, recipient, asset, amount, expiration, oracle_id) → u64`
  - [x] Call `sender.require_auth()` — sender must cryptographically approve the lock
  - [x] Validate `amount > 0` — panic if not
  - [x] Invoke `token::Client::new(&env, &asset).transfer(&sender, &env.current_contract_address(), &amount)`
  - [x] Increment `IntentCounter` and use the new value as the intent ID
  - [x] Store `Intent { sender, recipient, asset, amount, expiration, oracle_id, status: Pending }` in persistent storage
  - [x] Return intent ID to caller
  - [ ] Validate recipient address is not the zero address
  - [ ] Validate expiration is in the future (`expiration > env.ledger().timestamp()`)
  - [ ] Emit `IntentCreated { intent_id, sender, recipient, amount, asset, expiration }` event
  - [ ] Extend persistent storage TTL for the new intent entry

---

### Issue #SC-07: `execute_intent` — Oracle-Triggered Fund Release
**Status:** ❌ PENDING | **Priority:** CRITICAL
**Labels:** `smart-contract`, `feature`, `escrow`, `oracle`
**Description:** Allows the registered oracle (or arbiter) to release locked funds to the recipient when the off-chain condition is confirmed met. This is the primary value delivery function of the protocol — without it, locked funds are permanently unrecoverable.
- **Tasks:**
  - [ ] Implement `execute_intent(env: Env, intent_id: u64)`
  - [ ] Fetch intent from persistent storage — panic with `IntentNotFound` if absent
  - [ ] Check `intent.status == IntentStatus::Pending` — panic with `AlreadySettled` if not
  - [ ] Call `intent.oracle_id.require_auth()` — only the registered oracle can trigger execution
  - [ ] For time-based intents: verify `env.ledger().timestamp() >= intent.expiration`
  - [ ] Transfer `intent.amount` of `intent.asset` from contract to `intent.recipient`
  - [ ] Update intent status to `IntentStatus::Executed` in persistent storage
  - [ ] Emit `IntentExecuted { intent_id, recipient, amount, asset }` event
  - [ ] Write unit test: valid oracle executes successfully
  - [ ] Write unit test: non-oracle caller is rejected
  - [ ] Write unit test: executing an already-executed intent panics

---

### Issue #SC-08: `refund_intent` — Sender Recovery After Expiry
**Status:** ❌ PENDING | **Priority:** CRITICAL
**Labels:** `smart-contract`, `feature`, `escrow`, `safety`
**Description:** Allows the original sender to reclaim locked funds after the intent has expired and the condition was never met. This is the critical safety net — without it, any funds locked via `create_intent` are permanently trapped with no path to recovery.
- **Tasks:**
  - [ ] Implement `refund_intent(env: Env, intent_id: u64)`
  - [ ] Fetch intent from persistent storage — panic with `IntentNotFound` if absent
  - [ ] Check `intent.status == IntentStatus::Pending` — panic with `AlreadySettled` if not
  - [ ] Call `intent.sender.require_auth()` — only the original sender can trigger a refund
  - [ ] Verify `env.ledger().timestamp() > intent.expiration` — panic with `NotExpired` if intent is still active
  - [ ] Transfer `intent.amount` of `intent.asset` from contract back to `intent.sender`
  - [ ] Update intent status to `IntentStatus::Refunded` in persistent storage
  - [ ] Emit `IntentRefunded { intent_id, sender, amount, asset }` event
  - [ ] Write unit test: sender reclaims funds after expiry
  - [ ] Write unit test: refund before expiry panics
  - [ ] Write unit test: refunding an already-refunded intent panics

---

### Issue #SC-09: Error Constants & Panic Standardisation
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `error-handling`, `architecture`
**Description:** Replace raw `panic!("string")` calls with typed Soroban error constants for consistent, machine-readable error reporting on the frontend and indexers.
- **Tasks:**
  - [ ] Define `#[contracterror]` enum `EpochSendError` with variants:
    - `AlreadyInitialized = 1`
    - `NotInitialized = 2`
    - `IntentNotFound = 3`
    - `AlreadySettled = 4`
    - `NotExpired = 5`
    - `InvalidAmount = 6`
    - `Unauthorized = 7`
    - `ContractPaused = 8`
  - [ ] Replace all `panic!("...")` in `lib.rs` with typed error returns using `Err(EpochSendError::...)`
  - [ ] Update all test assertions to check for specific error variants

---

### Issue #SC-10: Soroban Event Emission
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `events`, `indexing`
**Description:** Emit structured Soroban events on every state-changing operation. Events are the signal layer for the frontend, oracle backend, and any future indexers to react to on-chain changes. Without events, the frontend must poll state blindly.
- **Tasks:**
  - [ ] Emit `("epochsend", "intent_created")` event with `{ intent_id, sender, recipient, amount, asset, expiration }` payload in `create_intent`
  - [ ] Emit `("epochsend", "intent_executed")` event with `{ intent_id, recipient, amount }` payload in `execute_intent`
  - [ ] Emit `("epochsend", "intent_refunded")` event with `{ intent_id, sender, amount }` payload in `refund_intent`
  - [ ] Emit `("epochsend", "initialized")` event with `{ admin }` in `initialize`
  - [ ] Emit `("epochsend", "upgraded")` event with `{ new_wasm_hash }` in `upgrade`
  - [ ] Write unit tests asserting events are emitted with correct payloads using `env.events().all()`

---

### Issue #SC-11: Persistent Storage TTL Management
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `storage`, `mainnet-readiness`
**Description:** Soroban's persistent storage entries automatically expire after a fixed number of ledgers. Without explicit TTL extension, intents will be garbage-collected on mainnet, permanently destroying on-chain state. This is a mainnet-critical bug.
- **Tasks:**
  - [ ] Research the current Soroban persistent storage TTL limit (currently ~1 year in ledgers)
  - [ ] Call `env.storage().persistent().extend_ttl(&DataKey::Intent(id), min_ttl, max_ttl)` in `create_intent`
  - [ ] Define `INTENT_MIN_TTL` and `INTENT_MAX_TTL` as constants (e.g., 1 year in ledgers)
  - [ ] Consider allowing TTL extension by anyone (to keep an intent alive) as a separate function
  - [ ] Write unit test confirming TTL is set on intent creation

---

### Issue #SC-12: `get_intent` — View Function
**Status:** ✅ COMPLETED | **Priority:** HIGH
**Labels:** `smart-contract`, `query`
**Description:** Provide a read-only view into a specific intent's state, allowing the frontend to display live on-chain data without signing a transaction.
- **Tasks:**
  - [x] Implement `get_intent(env: Env, intent_id: u64) -> Option<Intent>`
  - [x] Read from persistent storage with `env.storage().persistent().get(&DataKey::Intent(intent_id))`
  - [x] Return `None` gracefully if the intent does not exist
  - [ ] Add `get_intent_count(env: Env) -> u64` — returns current `IntentCounter` value
  - [ ] Add `intent_exists(env: Env, intent_id: u64) -> bool` — convenience check for frontend validation

---

### Issue #SC-13: Intent ID Registry per Sender
**Status:** 🔜 FUTURE | **Priority:** MEDIUM
**Labels:** `smart-contract`, `query`, `feature`
**Description:** Without a per-sender index, the frontend cannot enumerate a user's intents without knowing their IDs in advance. This requires a new storage data structure.
- **Tasks:**
  - [ ] Add `DataKey::SenderIntents(Address)` → `Vec<u64>` to store a list of intent IDs per sender
  - [ ] Append new `intent_id` to the sender's list inside `create_intent`
  - [ ] Implement `get_intents_by_sender(env: Env, sender: Address) -> Vec<u64>`
  - [ ] Handle empty case (sender has no intents) gracefully
  - [ ] Write unit test: create 3 intents from same sender, verify all 3 IDs returned

---

## 🔐 Module 3: Security & Access Control (SC-14 → SC-19)

### Issue #SC-14: Oracle Address Registry
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `security`, `oracle`
**Description:** The current implementation accepts any address as `oracle_id` at intent creation time. A registry allows the admin to pre-approve trusted oracle addresses, preventing users from designating malicious oracles.
- **Tasks:**
  - [ ] Add `DataKey::ApprovedOracles` → `Vec<Address>` to instance storage
  - [ ] Implement `register_oracle(env: Env, oracle: Address)` (admin-only)
  - [ ] Implement `revoke_oracle(env: Env, oracle: Address)` (admin-only)
  - [ ] Implement `is_oracle_approved(env: Env, oracle: Address) -> bool`
  - [ ] Optionally: validate `oracle_id` is in the approved registry inside `create_intent`
  - [ ] Emit `OracleRegistered { oracle }` and `OracleRevoked { oracle }` events
  - [ ] Write unit tests for registration, revocation, and rejection of unapproved oracle

---

### Issue #SC-15: Emergency Pause Mechanism
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `security`, `admin`
**Description:** A circuit-breaker allowing the admin to freeze all new intent creation in the event of a discovered vulnerability or exploit. Existing intents can still be executed or refunded during a pause.
- **Tasks:**
  - [ ] Add `DataKey::Paused` → `bool` to instance storage
  - [ ] Implement `set_paused(env: Env, paused: bool)` (admin-only)
  - [ ] Add `assert_not_paused(&env)` check at the start of `create_intent`
  - [ ] Implement `is_paused(env: Env) -> bool` as a public view function
  - [ ] Emit `ContractPaused { by: admin }` and `ContractUnpaused { by: admin }` events
  - [ ] Write unit test: intent creation is blocked when paused
  - [ ] Write unit test: `execute_intent` and `refund_intent` are NOT blocked by pause (funds must always be recoverable)

---

### Issue #SC-16: Per-Intent Amount Validation & Caps
**Status:** ❌ PENDING | **Priority:** MEDIUM
**Labels:** `smart-contract`, `security`, `risk-management`
**Description:** Add configurable caps to prevent single intents from locking excessively large amounts, limiting protocol risk exposure in the early stages.
- **Tasks:**
  - [ ] Add `DataKey::MaxIntentAmount` → `i128` to instance storage
  - [ ] Implement `set_max_intent_amount(env: Env, max: i128)` (admin-only)
  - [ ] Validate `amount <= max_intent_amount` (if cap is set) inside `create_intent`
  - [ ] Panic with `EpochSendError::AmountExceedsCap` if validation fails
  - [ ] Write unit test: intent creation fails when amount exceeds cap

---

### Issue #SC-17: Admin Transfer Function
**Status:** 🔜 FUTURE | **Priority:** MEDIUM
**Labels:** `smart-contract`, `admin`, `governance`
**Description:** The current admin is immutable after initialisation (except via WASM upgrade). Add a safe two-step admin transfer process.
- **Tasks:**
  - [ ] Implement `propose_admin(env: Env, new_admin: Address)` — current admin proposes a candidate
  - [ ] Implement `accept_admin(env: Env)` — candidate accepts, completing the transfer
  - [ ] Store `DataKey::PendingAdmin` → `Address` between the two steps
  - [ ] Emit `AdminTransferProposed { new_admin }` and `AdminTransferred { old_admin, new_admin }` events
  - [ ] Write unit test for full two-step transfer flow

---

### Issue #SC-18: Reentrancy Guard
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `smart-contract`, `security`
**Description:** Although Soroban's execution model significantly limits reentrancy risk, explicitly enforce a Checks-Effects-Interactions pattern in all state-changing functions to ensure audit-readiness.
- **Tasks:**
  - [ ] Audit `create_intent`, `execute_intent`, `refund_intent` for CEI pattern compliance
  - [ ] Ensure all state writes (`storage().set(...)`) happen BEFORE external token transfers
  - [ ] Document CEI compliance in inline code comments for each function
  - [ ] Add note in `docs/SMARTCONTRACT_GUIDE.md` explaining the pattern

---

### Issue #SC-19: Secret Key & Sensitive File Audit
**Status:** ❌ PENDING | **Priority:** CRITICAL
**Labels:** `security`, `devops`, `cleanup`
**Description:** The `smartcontract/.env.deploy` file contains what appears to be a committed real Stellar secret key from a previous project. This must be audited and any exposed keys rotated immediately.
- **Tasks:**
  - [ ] Audit `smartcontract/.env.deploy` — identify any real secret keys present
  - [ ] Rotate any exposed Stellar secret keys immediately (generate new keypairs)
  - [ ] Add `smartcontract/.env.deploy` explicitly to `smartcontract/.gitignore`
  - [ ] Run `git log --all --full-history -- "**/.env.deploy"` to check if the key appears in git history
  - [ ] If present in history: rewrite git history using `git filter-repo` or contact GitHub support for private repo scrubbing
  - [ ] Add a CI step that scans for hardcoded `S...` Stellar secret patterns using `trufflehog` or similar

---

## 🧪 Module 4: Testing & Verification (SC-20 → SC-25)

### Issue #SC-20: Complete Unit Test Suite
**Status:** 🔨 IN PROGRESS | **Priority:** CRITICAL
**Labels:** `testing`, `rust`
**Description:** The current test suite has exactly 1 test covering the happy-path `create_intent`. Every public function must be covered with at minimum one passing and one failing test.
- **Tasks:**
  - [x] `test_create_intent` — happy path: funds locked, intent stored, ID returned
  - [ ] `test_initialize_twice_panics` — second `initialize` call must panic
  - [ ] `test_create_intent_zero_amount_panics` — amount = 0 should be rejected
  - [ ] `test_execute_intent_by_oracle` — valid oracle signs and releases funds to recipient
  - [ ] `test_execute_intent_unauthorized` — non-oracle caller is rejected
  - [ ] `test_execute_already_executed_panics` — double-execution is blocked
  - [ ] `test_refund_after_expiry` — sender reclaims funds after timestamp passes
  - [ ] `test_refund_before_expiry_panics` — early refund is blocked
  - [ ] `test_refund_already_refunded_panics` — double-refund is blocked
  - [ ] `test_upgrade_by_non_admin_panics` — upgrade auth check is enforced

---

### Issue #SC-21: Edge Case & Boundary Tests
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `testing`, `security`
**Description:** Cover boundary conditions that a production contract is likely to encounter under adversarial or extreme conditions.
- **Tasks:**
  - [ ] Test `get_intent` on a non-existent ID — should return `None`, not panic
  - [ ] Test creating intent with expiration in the past — should still succeed (expiration is stored, not validated at creation)
  - [ ] Test intent with `amount = i128::MAX` — verify no overflow in storage
  - [ ] Test the intent counter increments correctly across 100 sequential intents
  - [ ] Test that a paused contract blocks `create_intent` but not `execute_intent` or `refund_intent`
  - [ ] Test `execute_intent` on an intent where oracle_id == sender (self-release pattern)

---

### Issue #SC-22: Test Snapshot Cleanup
**Status:** ❌ PENDING | **Priority:** MEDIUM
**Labels:** `testing`, `cleanup`
**Description:** The `test_snapshots/` directory contains 3 snapshot files. Two (`test_manual_execute.1.json`, `test_refund.1.json`) reference the old `create_escrow` / `execute` / `refund` function names that no longer exist in `lib.rs`. These are orphaned artefacts that will cause confusion and potential CI failures.
- **Tasks:**
  - [ ] Delete `smartcontract/test_snapshots/test/test_manual_execute.1.json` (references non-existent `create_escrow` + `execute` functions)
  - [ ] Delete `smartcontract/test_snapshots/test/test_refund.1.json` (references non-existent `refund` function)
  - [ ] Confirm `test_create_intent.1.json` is still valid against current `lib.rs`
  - [ ] Regenerate snapshots after implementing `execute_intent` and `refund_intent` tests
  - [ ] Add `test_snapshots/` to `.gitignore` to prevent future snapshot commits (already in root `.gitignore` — verify it applies to the `smartcontract/` subdirectory)

---

### Issue #SC-23: Integration Tests with Mock Token
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `testing`, `integration`
**Description:** End-to-end tests simulating the full lifecycle of a payment intent: create → execute → verify balances, and create → expire → refund → verify balances.
- **Tasks:**
  - [ ] Use `env.register_stellar_asset_contract(admin)` to deploy a mock SAC token
  - [ ] Write `test_full_lifecycle_execute`: create intent → oracle calls execute → verify recipient received funds, contract balance is 0, intent status is Executed
  - [ ] Write `test_full_lifecycle_refund`: create intent → advance ledger past expiration → sender calls refund → verify sender recovered funds, contract balance is 0, intent status is Refunded
  - [ ] Write `test_multiple_concurrent_intents`: create 5 intents with different conditions, execute 3, refund 2 — verify each intent state is independent

---

### Issue #SC-24: Fuzz Testing on Math & Counter Operations
**Status:** 🔜 FUTURE | **Priority:** MEDIUM
**Labels:** `testing`, `security`, `fuzz`
**Description:** Use property-based testing to verify that the intent counter and amount handling are safe against overflow, underflow, and unexpected input values.
- **Tasks:**
  - [ ] Write a fuzz test targeting `create_intent` with randomised `amount` values (including negative and MAX values)
  - [ ] Verify intent counter never overflows `u64::MAX` under any sequence of creates
  - [ ] Verify that token transfer amounts always match stored intent amounts exactly (no precision loss)
  - [ ] Integrate `arbitrary` crate for property-based testing if not already in scope

---

### Issue #SC-25: CI Pipeline Enhancements
**Status:** 🔨 IN PROGRESS | **Priority:** HIGH
**Labels:** `devops`, `ci`
**Description:** The current CI pipeline is minimal — it builds the WASM binary and runs tests. Expand it to include linting, WASM artifact uploads, and code coverage.
- **Tasks:**
  - [x] `cargo build --target wasm32-unknown-unknown --release` on every push
  - [x] `cargo test` on every push
  - [ ] Add `cargo clippy -- -D warnings` to enforce lint rules
  - [ ] Add `cargo fmt --check` to enforce code formatting
  - [ ] Upload compiled `epochsend_contract.wasm` as a CI artefact for manual inspection
  - [ ] Add `cargo audit` step to scan dependencies for known CVEs
  - [ ] Cache Cargo registry and build artefacts between CI runs (currently no caching — slow)

---

## 🚀 Module 5: Infrastructure, Deployment & Cleanup (SC-26 → SC-30)

### Issue #SC-26: Deploy Scripts & Automation
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `devops`, `deployment`
**Description:** Automate the full deployment lifecycle — compile, deploy, initialise — so that any team member can deploy to Testnet or Mainnet with a single command.
- **Tasks:**
  - [ ] Create `scripts/deploy.sh` — compiles WASM, deploys to Stellar Testnet, runs `initialize`
  - [ ] Create `scripts/deploy-mainnet.sh` — same, but targeting Mainnet with safety prompts
  - [ ] Create `scripts/invoke.sh` — convenience wrapper for calling contract functions via `soroban-cli`
  - [ ] Document deploy steps in `docs/SMARTCONTRACT_GUIDE.md`
  - [ ] Add deployed contract address to `.env.example` comments as an example

---

### Issue #SC-27: EVM Scaffold Cleanup
**Status:** ❌ PENDING | **Priority:** HIGH
**Labels:** `cleanup`, `devops`
**Description:** The `smartcontract/` directory contains a large amount of dead code copy-pasted from a previous EVM/Solidity project (ForgeX). These files are irrelevant to the Stellar/Soroban stack and pollute the repository with incorrect, misleading content.
- **Tasks:**
  - [ ] Delete `smartcontract/contracts/` directory (Solidity `.sol` files — wrong chain)
  - [ ] Delete `smartcontract/test/` directory (Hardhat TypeScript tests — wrong stack)
  - [ ] Delete `smartcontract/hardhat.config.ts` (EVM config — wrong chain)
  - [ ] Delete `smartcontract/package.json` and `smartcontract/package-lock.json` (npm/Hardhat deps — wrong stack)
  - [ ] Delete `smartcontract/tsconfig.json` (TypeScript config for Hardhat — not needed)
  - [ ] Delete `smartcontract/README.md` (references wrong project branding)
  - [ ] Delete `smartcontract/TODO.md` (ForgeX ERC-4626 task list — entirely irrelevant)
  - [ ] Update `smartcontract/.gitignore` to remove Hardhat-specific entries, add Soroban-specific ones
  - [ ] Verify `cargo build` and `cargo test` still pass after cleanup

---

### Issue #SC-28: Soroban SDK Version Update
**Status:** 🔜 FUTURE | **Priority:** MEDIUM
**Labels:** `maintenance`, `upgrade`
**Description:** The contract currently uses `soroban-sdk = "20.0.0"`. The SDK is now at v22.x with performance improvements, new storage APIs, and updated event handling. Upgrading ensures compatibility with the latest Stellar Protocol releases.
- **Tasks:**
  - [ ] Research breaking changes between v20 and v22 in the Soroban SDK changelog
  - [ ] Update `soroban-sdk` in `Cargo.toml` to `"22.0.0"` (or latest stable)
  - [ ] Update `derive_arbitrary` pin in `Cargo.lock` if required for the new version
  - [ ] Run `cargo test` and verify all tests still pass
  - [ ] Update CI to use the latest `soroban-cli` compatible with SDK v22

---

### Issue #SC-29: Stellar Expert Verification & Testnet Deployment Record
**Status:** ❌ PENDING | **Priority:** LOW
**Labels:** `deployment`, `transparency`
**Description:** Deploy the contract to Stellar Testnet and verify it on Stellar Expert / Stellar Laboratory so the frontend team can integrate against a real contract address.
- **Tasks:**
  - [ ] Deploy current `create_intent`-capable contract to Testnet using `scripts/deploy.sh`
  - [ ] Record the deployed contract address in `docs/SMARTCONTRACT_GUIDE.md` and `.env.example`
  - [ ] Verify contract WASM hash matches the compiled binary on Stellar Expert
  - [ ] Run `create_intent` from the frontend against the Testnet deployment and confirm end-to-end flow works

---

### Issue #SC-30: `SMARTCONTRACT_GUIDE.md` — Technical Doc Expansion
**Status:** 🔨 IN PROGRESS | **Priority:** MEDIUM
**Labels:** `documentation`
**Description:** Expand the existing guide to cover the complete integration path from WASM compilation through to frontend invocation.
- **Tasks:**
  - [x] Basic Soroban setup and SDK overview
  - [ ] Add section: "Calling `create_intent` from the Frontend" (XDR encoding, parameter types)
  - [ ] Add section: "Calling `execute_intent` from the Oracle Backend" (Node.js + Stellar SDK example)
  - [ ] Add section: "Reading on-chain events" (how to listen for `IntentCreated`, `IntentExecuted`, `IntentRefunded`)
  - [ ] Add section: "Contract Deployment Walkthrough" (step-by-step with `soroban-cli` commands)
  - [ ] Add section: "Testing Locally" (Soroban testutils, mock auth, `mock_all_auths()` pattern)

---

## 📌 Issue Numbering Reference

| Range | Module |
|---|---|
| SC-01 – SC-05 | Foundation & State Management |
| SC-06 – SC-13 | Core Escrow Logic |
| SC-14 – SC-19 | Security & Access Control |
| SC-20 – SC-25 | Testing & Verification |
| SC-26 – SC-30 | Infrastructure, Deployment & Cleanup |

---

## 📊 Implementation Priority Matrix

| Priority | Issues | Block Reason |
|---|---|---|
| 🔴 **Ship Blockers** | SC-07, SC-08, SC-19 | Contract is non-functional without execute/refund. Secret key is a live security risk. |
| 🟡 **Pre-Testnet** | SC-09, SC-10, SC-11, SC-20, SC-22, SC-26 | Needed for a usable, observable Testnet deployment |
| 🟢 **Pre-Mainnet** | SC-14, SC-15, SC-16, SC-18, SC-23, SC-24, SC-27, SC-28 | Required for a production-grade, audited contract |
| 🔵 **Phase 2+** | SC-13, SC-17, SC-29, SC-30 | Nice-to-have, post-MVP improvements |

---

*EpochSend Smart Contracts — Programmable escrow for the Stellar Network. Building in public.*
