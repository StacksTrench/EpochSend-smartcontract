#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, token, Address, Env};

#[contracttype]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DataKey {
    Sender,
    Recipient,
    Amount,
    ExecuteAt,
    Arbiter,
    ConditionType,
    Executed,
    Refunded,
    Token,
}

#[contracttype]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ConditionType {
    Timestamp = 0,
    Manual = 1,
}

#[contract]
pub struct ConditionalPayment;

#[contractimpl]
impl ConditionalPayment {
    pub fn create_escrow(
        env: Env,
        sender: Address,
        recipient: Address,
        token: Address,
        amount: i128,
        condition_type: ConditionType,
        condition_data: u64,
        arbiter: Address,
    ) {
        sender.require_auth();

        if env.storage().instance().has(&DataKey::Sender) {
            panic!("Escrow already initialized");
        }

        let token_client = token::Client::new(&env, &token);
        token_client.transfer(&sender, &env.current_contract_address(), &amount);

        env.storage().instance().set(&DataKey::Sender, &sender);
        env.storage().instance().set(&DataKey::Recipient, &recipient);
        env.storage().instance().set(&DataKey::Token, &token);
        env.storage().instance().set(&DataKey::Amount, &amount);
        env.storage().instance().set(&DataKey::ConditionType, &condition_type);
        env.storage().instance().set(&DataKey::Executed, &false);
        env.storage().instance().set(&DataKey::Refunded, &false);

        if condition_type == ConditionType::Timestamp {
            env.storage().instance().set(&DataKey::ExecuteAt, &condition_data);
        } else if condition_type == ConditionType::Manual {
            env.storage().instance().set(&DataKey::Arbiter, &arbiter);
        }
    }

    pub fn execute(env: Env) {
        let executed: bool = env.storage().instance().get(&DataKey::Executed).unwrap_or(false);
        let refunded: bool = env.storage().instance().get(&DataKey::Refunded).unwrap_or(false);
        
        if executed || refunded {
            panic!("Already executed or refunded");
        }

        let condition_type: ConditionType = env.storage().instance().get(&DataKey::ConditionType).unwrap();
        
        if condition_type == ConditionType::Timestamp {
            let execute_at: u64 = env.storage().instance().get(&DataKey::ExecuteAt).unwrap();
            if env.ledger().timestamp() < execute_at {
                panic!("Condition not met: Timestamp not reached");
            }
        } else if condition_type == ConditionType::Manual {
            let arbiter: Address = env.storage().instance().get(&DataKey::Arbiter).unwrap();
            arbiter.require_auth();
        }

        env.storage().instance().set(&DataKey::Executed, &true);

        let recipient: Address = env.storage().instance().get(&DataKey::Recipient).unwrap();
        let token: Address = env.storage().instance().get(&DataKey::Token).unwrap();
        let amount: i128 = env.storage().instance().get(&DataKey::Amount).unwrap();

        let token_client = token::Client::new(&env, &token);
        token_client.transfer(&env.current_contract_address(), &recipient, &amount);
    }

    pub fn refund(env: Env) {
        let executed: bool = env.storage().instance().get(&DataKey::Executed).unwrap_or(false);
        let refunded: bool = env.storage().instance().get(&DataKey::Refunded).unwrap_or(false);
        
        if executed || refunded {
            panic!("Already executed or refunded");
        }

        let sender: Address = env.storage().instance().get(&DataKey::Sender).unwrap();
        sender.require_auth(); 

        env.storage().instance().set(&DataKey::Refunded, &true);

        let token: Address = env.storage().instance().get(&DataKey::Token).unwrap();
        let amount: i128 = env.storage().instance().get(&DataKey::Amount).unwrap();

        let token_client = token::Client::new(&env, &token);
        token_client.transfer(&env.current_contract_address(), &sender, &amount);
    }
}

mod test;
