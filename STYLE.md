# Code Style Guide - EpochSend Smart Contracts

## Rust (Soroban Smart Contracts)

- **Formatting:** Always run `cargo fmt` before submitting PRs.
- **Linting:** Run `cargo clippy` and resolve all warnings.
- **Version:** Always use the latest stable Soroban SDK.
- **Errors:** Use custom `Error` enums for failures. Do not use generic panics unless absolutely necessary.
- **Safety:** Always use the `Env` object for authorization and state access. Ensure `require_auth()` is used correctly for all sensitive state changes.
- **State Limits:** Optimize contract data footprint. Use `Temporary` storage for data that can expire, and `Persistent` storage strictly for critical permanent balances or configurations.
- **Logic:** Keep logic clean, separate concerns between the factory and implementation.
- **Testing:** Write comprehensive unit tests in `test.rs` for every contract function. Ensure complete branch coverage for all `if/else` paths.

## Project Conventions

### File Naming
- Contracts: `contract.rs`, `factory.rs`
- Tests: `test.rs`
- Types: `types.rs`, `events.rs`

### Git Commits
- Follow modular commit philosophy.
- Commit after meaningful changes.
- Run `cargo build --target wasm32-unknown-unknown --release` before committing.

## Integrity Checks

- **Contracts:** `cargo build --target wasm32-unknown-unknown --release` should execute flawlessly.
- **Tests:** `cargo test` must pass all suites without errors.

---

*Always ensure the smart contract compiles correctly and securely on Stellar.*
