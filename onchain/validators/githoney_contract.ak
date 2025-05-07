use aiken/collection/dict
use aiken/collection/list
use cardano/assets.{PolicyId}
use cardano/transaction.{Datum, OutputReference, Redeemer, ScriptContext}
use checks.{is_signed_by}
use types.{
  AddRewards, Assign, Claim, Close, CloseSettings, GithoneyContractRedeemers,
  GithoneyDatum, Merge, SettingsDatum, SettingsRedeemers, UpdateSettings,
}
use validations.{
  add_rewards, assign, claim, close, close_settings, merge, minting_policy,
  minting_policy_settings, reference_input_settings_with_NFT, update_settings,
}

validator githoney(settings_policy_id: PolicyId) {
  spend(
    datum: Option<GithoneyDatum>,
    redeemer: GithoneyContractRedeemers,
    input_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum

    let script_input = get_unique_script_input(input_ref, tx).output
    expect Script(bounty_id_policy) = script_input.address.payment_credential
    expect [Pair(bounty_id_name, 1)] =
      // expect only one bounty token id
      script_input.value |> tokens(bounty_id_policy) |> dict.to_pairs

    when redeemer is {
      AddRewards -> add_rewards(datum, script_input, tx)
      Assign -> assign(datum, script_input, tx)
      Merge ->
        merge(
          bounty_id_policy,
          bounty_id_name,
          settings_policy_id,
          datum,
          script_input,
          tx,
        )
      Close -> close(bounty_id_policy, bounty_id_name, datum, tx)
      Claim -> claim(bounty_id_policy, bounty_id_name, datum, script_input, tx)
    }
  }

  mint(_redeemer: Redeemer, _minting_policy: PolicyId, tx: Transaction) {
    let settings_datum =
      reference_input_settings_with_NFT(tx, settings_policy_id)
    let (own_policy, bounty_id, minted_quantity) = get_minting_info(tx)
    if minted_quantity == -1 {
      True
    } else {
      let script_output =
        utxo_at_paid_to_address(tx.outputs, from_script(own_policy), 0)
      let githoney_output =
        utxo_at_paid_to_address(tx.outputs, settings_datum.githoney_address, 1)
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
            |> assets.add(own_policy, bounty_id, -1)
        )

      is_creation_fee_paid? && is_minting_only_one_bounty_id_token? && is_script_output_address_valid? && valid_datum? && valid_value? && valid_deposit?
    }
  }

  else(_) {
    fail
  }
}

validator settings {
  spend(
    datum: Option<SettingsDatum>,
    redeemer: SettingsRedeemers,
    input_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum
    let script_input = get_unique_script_input(tx, input_ref).output
    expect [(settings_policy_policy, _, 1)] =
      script_input.value
        |> assets.without_lovelace()
        |> assets.flatten()

    when redeemer is {
      UpdateSettings ->
        update_settings(datum, script_input, settings_policy_policy, tx)
      CloseSettings ->
        close_settings(datum, script_input, settings_policy_policy, tx)
    }
  }

  else(_) {
    fail
  }
}

validator settings(utxo_ref: OutputReference) {
  mint(_redeemer: Redeemer, minting_policy: PolicyId, tx: Transaction) {
    minting_policy_settings(utxo_ref, tx)
  }

  else(_) {
    fail
  }
}

validator badges_policy(utxo_ref: OutputReference, nonce: Int) {
  mint(_redeemer: Redeemer, minting_policy: PolicyId, tx: Transaction) {
    let is_outref_in_inputs =
      list.any(tx.inputs, fn(input) { input.output_reference == utxo_ref })

    let is_valid_nonce = nonce >= 0

    is_outref_in_inputs? && is_valid_nonce?
  }

  else(_) {
    fail
  }
}

validator badges_contract(settings_policy_id: PolicyId) {
  spend(
    _datum: Datum,
    _redeemer: Redeemer,
    input_ref: OutputReference,
    tx: Transaction,
  ) {
    let settings_datum =
      reference_input_settings_with_NFT(tx.transaction, settings_policy_id)
    let is_signed_by_githoney =
      is_signed_by(tx, settings_datum.githoney_address.payment_credential)
    is_signed_by_githoney
  }

  else(_) {
    fail
  }
}
