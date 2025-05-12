use aiken/collection/list.{head}
use cardano/assets.{from_lovelace, merge, negate}
use cardano/transaction.{NoDatum, Output, Transaction}
use githoney_contract
use mocks
use test_utils.{
  add_extra_signature, add_output, mk_burn_transaction,
  remove_mint_from_context, script_input_without_bounty_id_token,
}
use types.{Close, GithoneyDatum}
use utils.{min_ada, to_githoney_datum}

test success() {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value
        |> assets.add(mocks.bounty_id_policy, mocks.bounty_id_name, -1),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> add_extra_signature(mocks.admin_addr)

  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), Close, script_input.output_reference, tx)
}

test success_with_contributor() {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value
        |> assets.add(mocks.bounty_id_policy, mocks.bounty_id_name, -1),
      datum: NoDatum,
      reference_script: None,
    }
  let contributor_pay_output =
    Output {
      address: mocks.mk_contributor_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(maintainer_pay_output)
      |> add_output(contributor_pay_output)
      |> add_extra_signature(mocks.admin_addr)

  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(input_datum), Close, script_input.output_reference, tx)
}

test without_admin_signature() {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)

  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), Close, script_input.output_reference, tx)
}

test contributor_bad_pay() fail {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(maintainer_pay_output)
      |> add_output(maintainer_pay_output)
      |> add_extra_signature(mocks.admin_addr)

  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(input_datum), Close, script_input.output_reference, tx)
}

test maintainer_bad_pay() {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: merge(script_input.output.value, negate(from_lovelace(min_ada))),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> add_extra_signature(mocks.admin_addr)

  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), Close, script_input.output_reference, tx)
}

test without_bounty_id_token() fail {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> add_extra_signature(mocks.admin_addr)
      |> script_input_without_bounty_id_token()

  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), Close, script_input.output_reference, tx)
}

test without_bounty_id_token_burn() fail {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value,
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> add_extra_signature(mocks.admin_addr)
      |> remove_mint_from_context()

  githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(datum), Close, script_input.output_reference, tx)
}

test already_merged_datum() {
  let tx = mk_burn_transaction(Close)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum = GithoneyDatum { ..datum, merged: True }
  let output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: script_input.output.value
        |> assets.add(mocks.bounty_id_policy, mocks.bounty_id_name, -1),
      datum: NoDatum,
      reference_script: None,
    }
  let tx =
    tx
      |> add_output(output)
      |> add_extra_signature(mocks.admin_addr)

  !githoney_contract.githoney.spend(mocks.settings_nft_policy, Some(input_datum), Close, script_input.output_reference, tx)
}
