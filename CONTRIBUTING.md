# Contributing to EpochSend Smart Contracts

Thank you for your interest in building the core escrow logic for the EpochSend protocol! This guide will help you contribute effectively.

## 🛠 Tech Stack

- **Smart Contracts:** Soroban (Rust)
- **Network:** Stellar (Testnet & Mainnet)

## 📝 Commit Guidelines

We follow a **Modular Commit** philosophy to ensure history is readable and revertable.

**The Golden Rule:**

> "Commit after every meaningful change, not every line."

- **Meaningful Change:** Completing a function, finishing a fix, adding a feature block, creating a file, or making a significant modification.
- **Avoid:** Micro-commits for single-line edits unless they are standalone fixes.
- **Frequency:** Commit often, but only when you finish a logical piece of work.

### Example Commit Messages

- `feat(contracts): implement time-based execution rules`
- `fix(auth): secure manual trigger verification`
- `docs: update deployment guide for Soroban CLI`
- `chore: update dependencies`

## 📋 Issue Tracking

1. Pick an issue from the `docs/ISSUES.md` file.
2. When you start, comment on the issue or mark it as "In Progress".
3. **When Completed:** You MUST update the issue file with:
   - Check the box `[x]`
   - Append your GitHub username and Date/Time.
   - _Example:_ `- [x] Implement payment creation (@bbkenny - 2024-04-13 14:00)`

## 🧪 Development Workflow

1. **Clone**: Clone the repo locally.
2. **Branch**: Create a feature branch (`feat/my-feature`).
3. **Develop**: Write code following the Style Guide (`STYLE.md`).
4. **Test**: Run `cargo test` in the `smartcontract` directory.
5. **Build**: Run `cargo build --target wasm32-unknown-unknown --release` before committing to ensure the WASM binary compiles.
6. **Commit**: Follow the commit guidelines above.

## Getting Help

Read the **Integration Guides** located in the `docs/` directory for detailed setup instructions.

---

_Help us transform payments from manual to intent-based on Stellar!_

### Testing
When running smart contract tests, snapshot files may be generated in the `test_snapshots/` directory. Please ensure this directory is not committed to version control. It has been added to `.gitignore`.
