#![cfg(test)]

use super::*;
use soroban_sdk::{testutils::Address as _, testutils::Ledger as _, Address, Env};
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
fn test_create_intent() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, EpochSendContract);
    let client = EpochSendContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    let sender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let arbiter = Address::generate(&env);

    client.initialize(&admin);

    let (token, token_admin) = create_token(&env, &admin);
    token_admin.mint(&sender, &1000);

    let intent_id = client.create_intent(
        &sender,
        &recipient,
        &token.address,
        &1000,
        &0, // expiration
        &arbiter,
    );

    assert_eq!(intent_id, 1);
    assert_eq!(token.balance(&sender), 0);
    assert_eq!(token.balance(&contract_id), 1000);

    let intent = client.get_intent(&intent_id).unwrap();
    assert_eq!(intent.sender, sender);
    assert_eq!(intent.recipient, recipient);
    assert_eq!(intent.amount, 1000);
    assert_eq!(intent.status, IntentStatus::Pending);
}

#[test]
fn test_execute_intent() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, EpochSendContract);
    let client = EpochSendContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    let sender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let oracle = Address::generate(&env);

    client.initialize(&admin);

    let (token, token_admin) = create_token(&env, &admin);
    token_admin.mint(&sender, &1000);

    let intent_id = client.create_intent(
        &sender,
        &recipient,
        &token.address,
        &1000,
        &100, // expiration
        &oracle,
    );

    // Execute the intent
    client.execute_intent(&intent_id);

    // Verify status is Executed
    let intent = client.get_intent(&intent_id).unwrap();
    assert_eq!(intent.status, IntentStatus::Executed);
    assert_eq!(token.balance(&recipient), 1000);
    assert_eq!(token.balance(&contract_id), 0);
}

#[test]
fn test_refund_intent() {
    let env = Env::default();
    env.mock_all_auths();

    let contract_id = env.register_contract(None, EpochSendContract);
    let client = EpochSendContractClient::new(&env, &contract_id);

    let admin = Address::generate(&env);
    let sender = Address::generate(&env);
    let recipient = Address::generate(&env);
    let oracle = Address::generate(&env);

    client.initialize(&admin);

    let (token, token_admin) = create_token(&env, &admin);
    token_admin.mint(&sender, &1000);

    let intent_id = client.create_intent(
        &sender,
        &recipient,
        &token.address,
        &1000,
        &100, // expiration
        &oracle,
    );

    // Adjust ledger time to trigger expiration refund
    let mut ledger_info = env.ledger().get();
    ledger_info.timestamp = 101;
    env.ledger().set(ledger_info);

    // Refund the intent
    client.refund_intent(&intent_id);

    // Verify status is Refunded
    let intent = client.get_intent(&intent_id).unwrap();
    assert_eq!(intent.status, IntentStatus::Refunded);
    assert_eq!(token.balance(&sender), 1000);
    assert_eq!(token.balance(&contract_id), 0);
}

