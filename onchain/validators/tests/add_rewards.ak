use aiken/collection/list.{foldl, head}
use cardano/assets.{add}
use cardano/transaction.{Output, Transaction}
use githoney_contract
use mocks.{token_a_policy, token_b_policy, token_c_policy}
use test_utils.{
  change_output_value, change_script_upper_bound, mk_transition_transaction,
  script_input_without_bounty_id_token,
}
use types.{AddRewards, GithoneyDatum}
use utils.{to_githoney_datum}

fn tokens_value(value: assets.Value) -> assets.Value {
  let tokens =
    [
      [token_c_policy, "token1"], [token_b_policy, "token2"],
      [token_a_policy, "token3"], [token_c_policy, "token4"],
      [token_b_policy, "token5"], [token_a_policy, "token6"],
      [token_c_policy, "token7"], [token_b_policy, "token8"],
      [token_a_policy, "token9"], [token_c_policy, "token10"],
      [token_b_policy, "token11"], [token_a_policy, "token12"],
      [token_c_policy, "token13"], [token_b_policy, "token14"],
    ]
  foldl(
    tokens,
    value,
    fn(token, acc) {
      expect [policy, name] = token
      acc |> add(policy, name, 1)
    },
  )
}

test success() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let tx = change_output_value(tx, 0, script_output_value)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), AddRewards, script_input.output_reference, tx)
}

test without_new_rewards() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), AddRewards, script_input.output_reference, tx)
}

test bad_datum() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let bad_datum = GithoneyDatum { ..datum, merged: True }
  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(bad_datum), AddRewards, script_input.output_reference, tx)
}

test after_deadline() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)

  let tx = change_output_value(tx, 0, script_output_value)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let tx = change_script_upper_bound(tx, datum.deadline + 1)
  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), AddRewards, script_input.output_reference, tx)
}

test without_bounty_id_token() fail {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let tx =
    tx
      |> change_output_value(0, script_output_value)
      |> script_input_without_bounty_id_token()
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), AddRewards, script_input.output_reference, tx)
}

test already_merged_datum() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let tx = change_output_value(tx, 0, script_output_value)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let bad_datum = GithoneyDatum { ..datum, merged: True }

  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(bad_datum), AddRewards, script_input.output_reference, tx)
}

test too_many_tokens() {
  let tx = mk_transition_transaction(AddRewards)
  expect Some(script_output) = head(tx.outputs)
  let script_output_value = script_output.value |> tokens_value
  let tx = change_output_value(tx, 0, script_output_value)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), AddRewards, script_input.output_reference, tx)
}
