use aiken/collection/dict
use aiken/collection/list
use aiken/option.{is_none, is_some}
use cardano/address.{ScriptCredential, from_script}
use cardano/assets.{
  AssetName, PolicyId, flatten, from_lovelace, quantity_of, tokens,
}
use cardano/transaction.{
  InlineDatum, Output, OutputReference, ScriptContext, Transaction,
}
use checks.{
  is_assign_datum_valid, is_merge_datum_valid, is_signed_by,
  is_tx_before_deadline, is_utxo_datum_valid, is_utxo_value_valid,
}
use types.{GithoneyDatum, SettingsDatum}
use utils.{
  get_first_output, get_minting_info, get_script_input,
  max_amount_of_tokens_admiteed, merge_payments_parts, min_ada,
  settings_token_name, to_githoney_datum, to_settings_datum, tokens_to_value,
  value_grater_than, value_grater_than_or_equal, utxo_at_paid_to_address
}

pub fn reference_input_settings_with_NFT(
  tx: Transaction,
  settings_policy_id: PolicyId,
) -> SettingsDatum {
  expect [ref_input] = tx.reference_inputs
  let has_settings_policy =
    quantity_of(ref_input.output.value, settings_policy_id, settings_token_name) == 1
  if !has_settings_policy {
    fail @"There should be exactly one settings NFT in the reference input"
  } else {
    to_settings_datum(ref_input.output.datum)
  }
}

pub fn add_rewards(
  datum: GithoneyDatum,
  script_input: Output,
  tx: Transaction,
) -> Bool {
  let script_output = utxo_at_paid_to_address(tx.outputs, script_input.address, 0)
  let new_datum = to_githoney_datum(script_output.datum)

  let is_tx_before_deadline = is_tx_before_deadline(tx, datum.deadline)
  let is_datum_the_same = datum == new_datum
  let is_value_grater_than_before =
    value_grater_than(script_output.value, script_input.value)
  let is_datum_not_merged = !datum.merged
  let are_policies_less_than =
    list.length(flatten(script_output.value)) <= max_amount_of_tokens_admiteed

  is_datum_not_merged? && is_datum_the_same? && is_tx_before_deadline? && is_value_grater_than_before? && are_policies_less_than?
}

pub fn assign(
  datum: GithoneyDatum,
  script_input: Output,
  tx: Transaction,
) -> Bool {
  let script_output = utxo_at_paid_to_address(tx.outputs, script_input.address, 0)
  let new_datum = to_githoney_datum(script_output.datum)

  let is_tx_before_deadline = is_tx_before_deadline(tx, datum.deadline)
  let contributor_isnt_assigned = is_none(datum.contributor_address)
  let is_new_datum_valid = is_assign_datum_valid(datum, new_datum)
  let expected_value = value.merge(script_input.value, from_lovelace(min_ada))
  let is_utxo_value_valid = script_output.value == expected_value

  is_new_datum_valid? && is_utxo_value_valid? && is_tx_before_deadline? && contributor_isnt_assigned?
}

pub fn merge(
  settings_policy_id: PolicyId,
  bounty_id_policy: PolicyId,
  bounty_id_name: AssetName,
  datum: GithoneyDatum,
  script_input: Output,
  tx: Transaction,
) -> Bool {
  let settings_datum = reference_input_settings_with_NFT(tx, settings_policy_id)
  let script_output = utxo_at_paid_to_address(tx.outputs, script_input.address, 0)
  let githoney_output =
    utxo_at_paid_to_address(tx.outputs, settings_datum.githoney_address, 1)
  let maintainer_output =
    utxo_at_paid_to_address(tx.outputs, datum.maintainer_address, 2)
  let new_datum = to_githoney_datum(script_output.datum)

  let is_tx_before_deadline = is_tx_before_deadline(tx, datum.deadline)
  let contributor_is_assigned = is_some(datum.contributor_address)
  let is_new_datum_valid = is_merge_datum_valid(datum, new_datum)
  let (script_value, githoney_value) =
    merge_payments_parts(
      datum.bounty_reward_fee,
      script_input.value,
      bounty_id_policy,
      bounty_id_name,
    )
  let is_utxo_value_valid = script_output.value == script_value
  let is_reward_fee_payed =
    value_grater_than_or_equal(
      githoney_output.value,
      githoney_value,
    )
  let is_signed_by_admin = is_signed_by(tx, datum.admin_wallet.payment_key)
  let is_maintainer_minada_payed =
    value_grater_than_or_equal(
      maintainer_output.value,
      from_lovelace(min_ada),
    )
  let is_datum_not_merged = !datum.merged

  is_datum_not_merged? && is_signed_by_admin? && is_new_datum_valid? && is_utxo_value_valid? && is_tx_before_deadline? && contributor_is_assigned? && is_maintainer_minada_payed? && is_reward_fee_payed?
}

pub fn close(
  bounty_id_policy: PolicyId,
  bounty_id_name: AssetName,
  datum: GithoneyDatum,
  tx: Transaction,
) -> Bool {
  let (policy_id, minted_name, minted_quantity) = get_minting_info(tx)
  let maintainer_output =
    utxo_at_paid_to_address(tx.outputs, datum.maintainer_address, 0)

  let is_maintainer_pay_valid =
    value_grater_than_or_equal(
      maintainer_output.value,
      tokens_to_value(datum.initial_value),
    )
  let are_payments_valid =
    when datum.contributor_address is {
      Some(contributor_address) -> {
        let contributor_output =
          utxo_at_paid_to_address(tx.outputs, contributor_address, 1)
        let is_contributor_pay_valid =
          value_grater_than_or_equal(
            contributor_output.value,
            from_lovelace(min_ada),
          )
        is_contributor_pay_valid? && is_maintainer_pay_valid?
      }

      None -> {
        is_maintainer_pay_valid?
      }
    }

  let is_signed_by_admin = is_signed_by(tx, datum.admin_wallet.payment_key)
  let is_bounty_id_token_burnt =
    minted_quantity == -1 && minted_name == bounty_id_name && policy_id == bounty_id_policy
  let is_datum_not_merged = !datum.merged

  is_datum_not_merged? && is_signed_by_admin? && are_payments_valid? && is_bounty_id_token_burnt?
}

pub fn claim(
  bounty_id_policy: PolicyId,
  bounty_id_name: AssetName,
  datum: GithoneyDatum,
  script_input: Output,
  tx: Transaction,
) -> Bool {
  expect Some(contributor_address) = datum.contributor_address
  expect Some(contributor_utxo) = utxo_at_paid_to_address(
    tx.outputs,
    contributor_address,
    0,
  )

  let (policy_id, minted_name, minted_quantity) = get_minting_info(tx)
  let is_contributor_pay_valid =
    value_grater_than_or_equal(
      contributor_utxo.value,
      script_input.value
        |> value.add(bounty_id_policy, bounty_id_name, -1),
    )
  let is_bounty_id_token_burnt =
    minted_quantity == -1 && minted_name == bounty_id_name && policy_id == bounty_id_policy

  datum.merged? && is_bounty_id_token_burnt? && is_contributor_pay_valid?
}

// Main validation of the githoney token minting policy
pub fn minting_policy(settings_policy_id: PolicyId, tx: Transaction) -> Bool {
  let settings_datum = reference_input_settings_with_NFT(tx, settings_policy_id)
  let (own_policy, bounty_id, minted_quantity) = get_minting_info(tx)
  let is_token_burned = minted_quantity == -1
  if is_token_burned {
    True
  } else {
    let script_output = utxo_at_paid_to_address(tx.outputs, from_script(own_policy), 0)
    let githoney_output = utxo_at_paid_to_address(tx.outputs, settings_datum.githoney_address, 1)
    let datum = to_githoney_datum(script_output.datum)

    let is_minting_only_one_bounty_id_token = minted_quantity == 1

    let is_creation_fee_paid =
      value_grater_than_or_equal(
        githoney_output.value,
        from_lovelace(settings_datum.bounty_creation_fee),
      )

    let valid_datum =
      is_utxo_datum_valid(settings_datum.bounty_reward_fee, tx, datum)
    let valid_value =
      is_utxo_value_valid(own_policy, bounty_id, script_output.value)

    let valid_deposit =
      tokens_to_value(datum.initial_value) == (
        script_output.value
          |> value.add(own_policy, bounty_id, -1)
      )

    is_creation_fee_paid? && is_minting_only_one_bounty_id_token? && valid_datum? && valid_value? && valid_deposit?
  }
}

// Settings Validation
pub fn update_settings(datum: SettingsDatum, tx: Transaction) -> Bool {
  let script_input = get_script_input(tx).output
  expect [(settings_policy_policy, _, settings_amount)] =
    script_input.value
      |> value.without_lovelace()
      |> value.flatten()

  let is_signed = is_signed_by(tx, datum.githoney_wallet.payment_key)

  let is_only_one_token_input = settings_amount == 1

  let script_output = utxo_at_paid_to_address(tx.outputs, script_input.address, 0)
  let is_settings_policy_in_output =
    quantity_of(
      script_output.value,
      settings_policy_policy,
      settings_token_name,
    ) == 1

  expect InlineDatum(new_datum) = script_output.datum
  expect _settings_datum: SettingsDatum = new_datum

  is_signed? && is_only_one_token_input? && is_settings_policy_in_output?
}

pub fn close_settings(datum: SettingsDatum, tx: Transaction) -> Bool {
  let script_input = get_script_input(tx).output
  expect [(settings_policy_policy, _, _)] =
    script_input.value
      |> value.without_lovelace()
      |> value.flatten()

  let (policy_id, minted_name, minted_quantity) = get_minting_info(tx)

  let is_settings_policy_burnt =
    minted_quantity == -1 && minted_name == settings_token_name && policy_id == settings_policy_policy
  let is_signed = is_signed_by(tx, datum.githoney_wallet.payment_key)

  let githoney_output = utxo_at_paid_to_address(tx.outputs, datum.githoney_address, 0)
  let is_githoney_pay_valid =
    value_grater_than_or_equal(
      githoney_output.value,
      script_input.value
        |> value.add(settings_policy_policy, settings_token_name, -1),
    )
  is_settings_policy_burnt? && is_signed? && is_githoney_pay_valid?
}

pub fn minting_policy_settings(
  utxo_ref: OutputReference,
  tx: Transaction,
) -> Bool {
  let (settings_policy, _, minted_quantity) = get_minting_info(tx)

  let is_token_burned = minted_quantity == -1
  if is_token_burned {
    True
  } else {
    let is_minting_only_one_setting_token = minted_quantity == 1
    let is_outref_in_inputs =
      list.any(tx.inputs, fn(input) { input.output_reference == utxo_ref })

    let script_output = utxo_at_paid_to_address(tx.outputs, from_script(settings_policy), 0)

    expect InlineDatum(datum) = script_output.datum
    expect _settings_datum: SettingsDatum = datum

    let is_setting_token_in_output =
      quantity_of(script_output.value, settings_policy, settings_token_name) == 1

    is_minting_only_one_setting_token? && is_outref_in_inputs? && is_setting_token_in_output?
  }
}
