# 📘 Product Requirements Document (PRD)

## Product Name: EpochSend

---

## 🧠 Overview

EpochSend is an intent-based payment protocol on **Stellar** that allows users to define conditions under which funds are automatically executed on-chain.

Instead of sending money immediately, users define rules such as:

- “Send when delivery is confirmed”
- “Pay every Friday”
- “Release funds after milestone completion”

The system converts user intent into enforceable on-chain payment logic using **Soroban smart contracts**.

---

## 🎯 Problem Statement

Payments today are:

- Manual
- Trust-based
- Non-conditional

Users often rely on:

- Verbal agreements, manual follow-ups, and third-party intermediaries — creating friction, disputes, and inefficiency.

---

## 💡 Solution

Enable programmable payments based on conditions on the Stellar network.

Users define:

- Recipient
- Amount
- Trigger condition

The protocol:

- Holds funds in escrow (Soroban contract)
- Monitors condition
- Executes payment automatically

---

## 🧩 Core Features

### 1. Conditional Payment Contracts (Soroban)

- Create payment with condition
- Funds locked in escrow
- Executes when condition is met

---

### 2. Supported Conditions (MVP)

#### Time-based

- Execute at timestamp
- Recurring payments (weekly/monthly)

#### Manual Trigger (trusted party)

- Recipient confirms delivery
- Multi-party approval

#### Oracle-based (Phase 2)

- GPS/location verification
- API-based triggers (via Soroban-compatible oracles)

---

### 3. Payment Types

- One-time conditional payments
- Recurring subscriptions
- Group contributions (threshold unlock)

---

### 4. Escrow System

- Funds locked in Soroban smart contract
- Refund logic if condition fails
- Optional dispute timeout

---

## 🔁 User Flow

1. User selects “Create Payment”
2. Inputs:
   - Amount
   - Recipient
   - Condition
3. Funds are deposited into Soroban contract
4. Condition monitored
5. Payment executes automatically on Stellar

---

## 🏗️ Architecture

### Smart Contracts (Soroban)

- `PaymentFactory`
  - Creates new payment contracts

- `ConditionalPayment`
  - Stores:
    - Sender
    - Recipient
    - Amount
    - Condition logic

---

### Frontend

- Next.js + TypeScript
- Wallet connection (Freighter Wallet / Stellar SDK)
- Mobile-first UI

---

## 🔐 Security Considerations

- Reentrancy protection
- Escrow fund safety
- Condition validation
- Timeout fallback logic

---

## 📊 Success Metrics

- Number of payments created
- Total transaction volume (USDC/XLM)
- Unique users
- Execution success rate

---

## 🚀 Roadmap

### Phase 1 (MVP)

- Time-based payments
- Manual trigger
- Simple UI on Stellar

### Phase 2

- Oracle integrations
- Recurring payments
- Notifications

### Phase 3

- SDK for developers
- API integrations
- Cross-app triggers

---

## 🎯 Positioning

A mobile-first payment protocol that transforms user intent into automated financial execution on the Stellar network.

---

## 🧠 Key Differentiator

Not just sending money — but defining behavior that money follows.
