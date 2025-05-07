use aiken/collection/dict
use aiken/collection/list
use aiken/option
use cardano/address.{Address, Script}
use cardano/assets.{
  AssetName, PolicyId, Value, flatten, from_asset, from_lovelace, merge,
  quantity_of, reduce, tokens, zero,
}
use cardano/script_context.{ScriptContext}
use cardano/transaction.{
  Datum, InlineDatum, Input, Output, OutputReference, Spend, Transaction,
}
use types.{GithoneyDatum, SettingsDatum, TokenInfo}

pub const settings_token_name: ByteArray = "settingsNFT"

pub const min_ada: Int = 3_000_000

pub const max_amount_of_tokens_admiteed: Int = 15

// Returns the minting information of a transaction.
pub fn get_minting_info(tx: Transaction) -> (PolicyId, AssetName, Int) {
  expect [info] = tx.mint |> flatten
  info
}

// Converts an arbitrary Data type into a GithoneyDatum.
pub fn to_githoney_datum(data: Data) -> GithoneyDatum {
  expect InlineDatum(datum): Datum = data
  expect githoney_datum: GithoneyDatum = datum
  githoney_datum
}

pub fn to_settings_datum(data: Data) -> SettingsDatum {
  expect InlineDatum(datum): Datum = data
  expect settings_datum: SettingsDatum = datum
  settings_datum
}

// Verifies if an input UTxO belongs to a script.
pub fn is_script_utxo(input: Input) -> Bool {
  when input.output.address.payment_credential is {
    Script(_) -> True
    _ -> False
  }
}

/// Returns the portfolio UTxO in the outputs of the transaction.
pub fn get_script_output(tx: Transaction) -> Output {
  expect [utxo] = tx.outputs |> list.filter(is_output_script_utxo)
  utxo
}

/// Verifies if an output UTxO belongs to a script.
pub fn is_output_script_utxo(output: Output) -> Bool {
  when output.address.payment_credential is {
    Script(_) -> True
    _ -> False
  }
}

pub fn get_unique_script_input(
  output_reference: OutputReference,
  inputs: List<Input>,
) -> Input {
  expect [input] =
    inputs
      |> list.filter(is_script_utxo)
  if input.output_reference == output_reference {
    input
  } else {
    fail @"The input does not coincide with the output reference"
  }
}

// Returns the total value paid to an address by a pending transaction.
// pub fn value_paid_to(wallet: Address, tx: Transaction) -> Value {
//   let Address { payment_credential, stake_credential } = wallet
//   let address =
//     when stake_credential is {
//       None -> address.from_verification_key(payment_credential)
//       Some(stake_k) ->
//         address.from_verification_key(payment_credential)
//           |> address.with_delegation_key(stake_k)
//     }

//   list.reduce(
//     tx.outputs,
//     value.zero(),
//     fn(acc, output) {
//       if output.address == address {
//         value.merge(acc, output.value)
//       } else {
//         acc
//       }
//     },
//   )
// }

pub fn get_input_with_asset(
  inputs: List<Input>,
  policy_id: PolicyId,
  asset_name: AssetName,
) {
  expect [input] =
    list.filter(
      inputs,
      fn(inp) {
        let quantity =
          tokens(inp.output.value, policy_id)
            |> dict.get(key: asset_name)
            |> option.or_else(0)
        quantity > 0
      },
    )
  input
}

pub fn value_grater_than(v1: Value, v2: Value) {
  let assets = merge(v1, v2)
  reduce(
    assets,
    False,
    fn(policy_id, token_name, _, acc) {
      let v1_quantity = quantity_of(v1, policy_id, token_name)
      let v2_quantity = quantity_of(v2, policy_id, token_name)
      if v1_quantity < v2_quantity {
        False
      } else {
        acc || v1_quantity > v2_quantity
      }
    },
  )
}

pub fn value_grater_than_or_equal(v1: Value, v2: Value) {
  v1 == v2 || value_grater_than(v1, v2)
}

pub fn merge_payments_parts(
  reward_fee: Int,
  script_value: Value,
  bounty_id_policy: PolicyId,
  bounty_id_name: AssetName,
) -> (Value, Value) {
  let reward_value = merge(script_value, from_lovelace(-(2 * min_ada)))
  let managment_assets =
    merge(
      from_asset(bounty_id_policy, bounty_id_name, 1),
      from_lovelace(min_ada),
    )
  let (script_part, fee_part) =
    reward_value
      |> reduce(
          (managment_assets, zero),
          fn(policy_id, token_name, quantity, acc) {
            if policy_id == bounty_id_policy {
              acc
            } else {
              let (reward, fee) = acc
              let fee_amount = quantity * reward_fee / ( 100 * 100 )
              let reward_amount = quantity - fee_amount
              (
                merge(reward, from_asset(policy_id, token_name, reward_amount)),
                merge(fee, from_asset(policy_id, token_name, fee_amount)),
              )
            }
          },
        )
  (script_part, fee_part)
}

pub fn tokens_to_value(tokens: List<TokenInfo>) -> Value {
  list.reduce(
    tokens,
    zero,
    fn(acc, token) {
      assets.add(
        acc,
        token.asset.policy_id,
        token.asset.asset_name,
        token.amount,
      )
    },
  )
}
