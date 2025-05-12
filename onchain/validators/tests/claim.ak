use aiken/collection/list.{head}
use cardano/assets.{from_lovelace}
use cardano/transaction.{NoDatum, Output, Transaction}
use githoney_contract
use mocks
use test_utils.{
  add_output, mk_burn_transaction, remove_mint_from_context,
  script_input_without_bounty_id_token,
}
use types.{Claim, GithoneyDatum}
use utils.{to_githoney_datum}

test success() {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      merged: True,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx = add_output(tx, output)

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}

test not_merged() {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx = add_output(tx, output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}

test without_contributor() fail {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum = GithoneyDatum { ..datum, merged: True }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx = add_output(tx, output)

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}

test contributor_bad_pay() {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      merged: True,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: from_lovelace(1),
      datum: NoDatum,
      reference_script: None,
    }
  let tx = add_output(tx, output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}

test without_bounty_id_token() fail {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      merged: True,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> script_input_without_bounty_id_token()

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}

test without_bounty_id_token_burn() fail {
  let tx = mk_burn_transaction(Claim)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      merged: True,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let output =
    Output {
      address: mocks.mk_contributor_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> remove_mint_from_context()

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Claim,
    script_input.output_reference,
    tx,
  )
}
