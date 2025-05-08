use aiken/collection/list.{head}
use cardano/assets.{
  ada_asset_name, ada_policy_id, add, from_asset, from_lovelace, merge,
}
use cardano/transaction.{NoDatum, Output, Transaction}
use githoney_contract
use mocks
use test_utils.{
  add_extra_signature, add_output, change_input_value, change_output_address,
  change_output_value, change_script_output_datum, change_script_upper_bound,
  mk_transition_transaction, script_input_without_bounty_id_token,
}
use types.{GithoneyDatum, Merge}
use utils.{min_ada, to_githoney_datum}

test success() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test bad_new_datum() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(input_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test bad_actual_datum() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      merged: True,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test bad_input_value() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test without_maintainer_pay() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(githoney_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test without_admin_signature() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test without_githoney_pay() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test bad_address() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)
      |> change_output_address(0, mocks.mk_contributor_address())

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test after_deadline() {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)
      |> change_script_upper_bound(datum.deadline + 1)

  !githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}

test without_bounty_id_token() fail {
  let tx = mk_transition_transaction(Merge)
  expect Some(script_input) = head(tx.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let input_datum =
    GithoneyDatum {
      ..datum,
      contributor_address: Some(mocks.mk_contributor_address()),
    }
  let new_datum = GithoneyDatum { ..input_datum, merged: True }
  expect Some(script_output) = head(tx.outputs)
  let script_input_value =
    script_output.value |> add(ada_policy_id, ada_asset_name, min_ada)
  let githoney_fee_amount = mocks.reward_amount * mocks.reward_fee / 10000
  let script_output_value =
    merge(
      script_output.value,
      from_asset(mocks.token_a_policy, mocks.token_a_name, -githoney_fee_amount),
    )

  let githoney_pay_output =
    Output {
      address: mocks.mk_githoney_address(),
      value: from_asset(
        mocks.token_a_policy,
        mocks.token_a_name,
        githoney_fee_amount,
      ),
      datum: NoDatum,
      reference_script: None,
    }

  let maintainer_pay_output =
    Output {
      address: mocks.mk_maintainer_address(),
      value: from_lovelace(min_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let tx =
    tx
      |> change_script_output_datum(new_datum)
      |> change_output_value(0, script_output_value)
      |> change_input_value(0, script_input_value)
      |> add_extra_signature(mocks.admin_addr)
      |> add_output(maintainer_pay_output)
      |> add_output(githoney_pay_output)
      |> script_input_without_bounty_id_token()

  githoney_contract.githoney.spend(
    mocks.settings_nft_policy,
    Some(input_datum),
    Merge,
    script_input.output_reference,
    tx,
  )
}
