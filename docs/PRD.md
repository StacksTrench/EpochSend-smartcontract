# 📘 Product Requirements Document (PRD)

## Product Name: EpochSend

---

## 🧠 Overview

EpochSend is a conditional payment protocol built on Stellar. It lets users define off-chain rules for how and when money moves on-chain.

Instead of immediate payments, funds are locked in a Soroban smart contract. The contract will only release them to the recipient when a specific off-chain event (like a delivery API webhook, database change, or external invoice trigger) is verified by our Express oracle backend.

---

## 🎯 Problem Statement

Traditional escrows are manual and slow. Blockchains are completely isolated and cannot read Web2 API webhooks on their own. EpochSend bridges this gap. It connects standard Web2 event webhooks directly to Soroban smart contract escrows.

---

## 💡 The Solution

Enable programmable payments based on off-chain conditions. 
Senders specify:
- Recipient
- Asset type & Amount
- `oracle_id` (the address of the verification service)
- `expiration` (dispute timeout)

The protocol locks funds in a Soroban smart contract, waits for the oracle to sign and submit a release transaction (`execute_intent`), or lets the sender claim a refund (`refund_intent`) if the event never happens before the expiration time.

---

## 🧩 Core Features (Soroban Contract)

### 1. Locked Intents
* Funds are safely held in persistent storage under a unique intent counter.
* The contract is non-custodial and secure.

### 2. Designate Oracle
* Senders define the specific oracle address (`oracle_id`) allowed to trigger the payment release.

### 3. Expiration Time-lock
* The ledger timestamp is checked to ensure refunds can only occur after the expiration time.

---

## 🔁 User Flow

1. Sender connected to Freighter connect creates an intent specifying amount, recipient, oracle, and expiration.
2. Funds transfer from the sender to the contract.
3. The Express backend receives an off-chain API webhook.
4. The backend verifies the webhook, signs a transaction, and calls `execute_intent` on the contract.
5. The contract transfers the tokens to the recipient.

---

## 🏗️ Architecture (On-chain)

### Smart Contract (Soroban)
* `EpochSendContract`
  * `initialize(env, admin)`: Configures admin controls.
  * `upgrade(env, new_wasm_hash)`: Upgrades WASM code.
  * `create_intent(sender, recipient, asset, amount, expiration, oracle_id)`: Locks funds and creates pending intent.
  * `get_intent(intent_id)`: Queries intent details.
  * `execute_intent(intent_id)`: Release funds (requires oracle signature).
  * `refund_intent(intent_id)`: Reclaim funds after expiration.

---

## 🔐 Security Considerations

- **Strict Authorization:** Only the designated `oracle_id` can trigger `execute_intent`. Only the original `sender` can trigger `refund_intent` (and only after expiration).
- **Checks-Effects-Interactions:** Intent status changes to `Executed` or `Refunded` *before* the contract transfers tokens, preventing reentrancy attacks.
- **WASM Upgrades:** Restricts code upgrades to authorized admins.
