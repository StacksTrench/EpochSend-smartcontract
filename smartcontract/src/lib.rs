#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, token, Address, BytesN, Env};

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DataKey {
    Admin,
    IntentCounter,
    Intent(u64),
}

#[contracttype]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IntentStatus {
    Pending = 0,
    Executed = 1,
    Refunded = 2,
}

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Intent {
    pub sender: Address,
    pub recipient: Address,
    pub asset: Address,
    pub amount: i128,
    pub expiration: u64,
    pub oracle_id: Address,
    pub status: IntentStatus,
}

#[contract]
pub struct EpochSendContract;

#[contractimpl]
impl EpochSendContract {
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("Already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage().instance().set(&DataKey::IntentCounter, &0u64);
    }

    pub fn upgrade(env: Env, new_wasm_hash: BytesN<32>) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        env.deployer().update_current_contract_wasm(new_wasm_hash);
    }

    pub fn create_intent(
        env: Env,
        sender: Address,
        recipient: Address,
        asset: Address,
        amount: i128,
        expiration: u64,
        oracle_id: Address,
    ) -> u64 {
        sender.require_auth();

        if amount <= 0 {
            panic!("Amount must be greater than zero");
        }

        // Transfer tokens from sender to contract
        let token_client = token::Client::new(&env, &asset);
        token_client.transfer(&sender, &env.current_contract_address(), &amount);

        // Get and increment intent counter
        let mut counter: u64 = env.storage().instance().get(&DataKey::IntentCounter).unwrap();
        counter += 1;
        env.storage().instance().set(&DataKey::IntentCounter, &counter);

        // Save the intent securely in persistent storage
        let intent = Intent {
            sender,
            recipient,
            asset,
            amount,
            expiration,
            oracle_id,
            status: IntentStatus::Pending,
        };

        env.storage().persistent().set(&DataKey::Intent(counter), &intent);

        counter
    }

    pub fn get_intent(env: Env, intent_id: u64) -> Option<Intent> {
        env.storage().persistent().get(&DataKey::Intent(intent_id))
    }

    pub fn execute_intent(env: Env, intent_id: u64) {
        let mut intent: Intent = env
            .storage()
            .persistent()
            .get(&DataKey::Intent(intent_id))
            .unwrap_or_else(|| panic!("Intent not found"));

        if intent.status != IntentStatus::Pending {
            panic!("Intent is not pending");
        }

        // Authenticate the oracle/executor
        intent.oracle_id.require_auth();

        // Transfer locked tokens from contract to recipient
        let token_client = token::Client::new(&env, &intent.asset);
        token_client.transfer(
            &env.current_contract_address(),
            &intent.recipient,
            &intent.amount,
        );

        // Update status and save
        intent.status = IntentStatus::Executed;
        env.storage().persistent().set(&DataKey::Intent(intent_id), &intent);
    }

    pub fn refund_intent(env: Env, intent_id: u64) {
        let mut intent: Intent = env
            .storage()
            .persistent()
            .get(&DataKey::Intent(intent_id))
            .unwrap_or_else(|| panic!("Intent not found"));

        if intent.status != IntentStatus::Pending {
            panic!("Intent is not pending");
        }

        // Check if expiration time has passed
        let current_time = env.ledger().timestamp();
        if current_time < intent.expiration {
            panic!("Intent has not expired yet");
        }

        // Transfer tokens back to sender
        let token_client = token::Client::new(&env, &intent.asset);
        token_client.transfer(
            &env.current_contract_address(),
            &intent.sender,
            &intent.amount,
        );

        // Update status and save
        intent.status = IntentStatus::Refunded;
        env.storage().persistent().set(&DataKey::Intent(intent_id), &intent);
    }
}

mod test;
