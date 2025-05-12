use aiken/collection/list.{head}
use cardano/assets.{ada_asset_name, ada_policy_id, add}
use cardano/transaction.{Output, Transaction}
use githoney_contract
use mocks
use test_utils.{
  change_output_value, change_script_output_datum, change_script_upper_bound,
  mk_transition_transaction, script_input_without_bounty_id_token,
}
use types.{Assign, GithoneyDatum}
use utils.{min_ada, to_githoney_datum}

test success() {
  let tx = mk_transition_transaction(Assign)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let new_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)

  let tx = change_script_output_datum(tx, new_datum)
  let tx = change_output_value(tx, 0, script_output_value)
  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(datum),
    Assign,
    script_input.output_reference,
    tx,
  )
}

test bad_datum() {
  let tx = mk_transition_transaction(Assign)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let new_datum = GithoneyDatum { ..datum, contributor_address: None }
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let tx = change_script_output_datum(tx, new_datum)
  let tx = change_output_value(tx, 0, script_output_value)
  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(datum),
    Assign,
    script_input.output_reference,
    tx,
  )
}

test bad_output_value() {
  let tx = mk_transition_transaction(Assign)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let new_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, 1000)
  let tx = change_script_output_datum(tx, new_datum)
  let tx = change_output_value(tx, 0, script_output_value)
  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(datum),
    Assign,
    script_input.output_reference,
    tx,
  )
}

test after_deadline() {
  let tx = mk_transition_transaction(Assign)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let new_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let tx = change_script_output_datum(tx, new_datum)
  let tx = change_output_value(tx, 0, script_output_value)
  let tx = change_script_upper_bound(tx, datum.deadline + 1)
  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(datum),
    Assign,
    script_input.output_reference,
    tx,
  )
}

test without_bounty_id_token() fail {
  let tx = mk_transition_transaction(Assign)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let new_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  expect Some(script_output) = head(tx.outputs)
  let script_output_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> script_input_without_bounty_id_token()

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(datum),
    Assign,
    script_input.output_reference,
    tx,
  )
}
