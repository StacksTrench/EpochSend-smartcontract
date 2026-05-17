#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, Address, Env};
use soroban_sdk::token::Client as TokenClient;
use soroban_sdk::token::StellarAssetClient as TokenAdminClient;

fn create_token<'a>(
    env: &Env,
    admin: &Address,
) -> (TokenClient<'a>, TokenAdminClient<'a>) {
    let contract_id = env.register_stellar_asset_contract(admin.clone());
    (
        TokenClient::new(env, &contract_id),
        TokenAdminClient::new(env, &contract_id),
    )
}

#[test]
fn test_manual_execute() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, ConditionalPayment);
    let client = ConditionalPaymentClient::new(&env, &contract_id);

    let sender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let arbiter = Address::generate(&env);
    let admin = Address::generate(&env);

    let (token, token_admin) = create_token(&env, &admin);
    
    token_admin.mint(&sender, &1000);

    client.create_escrow(
        &sender,
        &recipient,
        &token.address,
        &1000,
        &ConditionType::Manual,
        &0,
        &arbiter,
    );

    assert_eq!(token.balance(&sender), 0);
    assert_eq!(token.balance(&contract_id), 1000);

    // Arbiter executes
    client.execute();

    assert_eq!(token.balance(&contract_id), 0);
    assert_eq!(token.balance(&recipient), 1000);
}

#[test]
fn test_refund() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, ConditionalPayment);
    let client = ConditionalPaymentClient::new(&env, &contract_id);

    let sender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let arbiter = Address::generate(&env);
    let admin = Address::generate(&env);

    let (token, token_admin) = create_token(&env, &admin);
    
    token_admin.mint(&sender, &1000);

    client.create_escrow(
        &sender,
        &recipient,
        &token.address,
        &1000,
        &ConditionType::Manual,
        &0,
        &arbiter,
    );

    assert_eq!(token.balance(&sender), 0);

    // Sender refunds
    client.refund();

    assert_eq!(token.balance(&contract_id), 0);
    assert_eq!(token.balance(&sender), 1000);
}
