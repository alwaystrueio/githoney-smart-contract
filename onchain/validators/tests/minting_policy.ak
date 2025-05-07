use aiken/collection/list
use cardano/address.{Address, Script}
use cardano/assets
use cardano/transaction.{NoDatum, Output, Transaction}
use mocks
use test_utils
use utils.{min_ada}
use validations.{minting_policy}

test general_test() {
  let ctx = test_utils.mk_mp_script_context()

  minting_policy(mocks.settings_nft_policy, ctx)
}

test wrong_datum() fail {
  let ctx = test_utils.mk_mp_script_context()

  expect Some(bounty_utxo) = list.head(ctx.transaction.outputs)
  let wrong_output = Output { ..bounty_utxo, datum: NoDatum }

  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction { ..ctx.transaction, outputs: [wrong_output] },
    }

  minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test no_reward_assets() {
  let ctx = test_utils.mk_mp_script_context()

  expect Some(outputs) = list.tail(ctx.transaction.outputs)
  let wrong_bounty = {
    expect Some(bounty_utxo) = list.head(ctx.transaction.outputs)
    Output {
      ..bounty_utxo,
      value: assets.from_lovelace(min_ada)
        |> assets.add(mocks.bounty_id_policy, mocks.bounty_id_name, 1),
    }
  }
  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        outputs: list.push(outputs, wrong_bounty),
      },
    }
  !minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test fee_not_paid() {
  let ctx = test_utils.mk_mp_script_context()

  expect Some(bounty_utxo) = list.head(ctx.transaction.outputs)
  let out_githoney_address =
    Output {
      address: mocks.mk_githoney_address(),
      value: assets.zero,
      datum: NoDatum,
      reference_script: None,
    }

  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        outputs: [bounty_utxo, out_githoney_address],
      },
    }
  !minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test wrong_value() {
  let ctx = test_utils.mk_mp_script_context()

  expect Some(outputs) = list.tail(ctx.transaction.outputs)
  let wrong_bounty = {
    expect Some(bounty_utxo) = list.head(ctx.transaction.outputs)
    Output { ..bounty_utxo, value: assets.from_lovelace(1_234_567) }
  }
  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        outputs: list.push(outputs, wrong_bounty),
      },
    }

  !minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test wrong_minted_amount() fail {
  let ctx = test_utils.mk_mp_script_context()

  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        mint: assets.to_minted_value(
          assets.from_asset(mocks.bounty_id_policy, mocks.bounty_id_name, 1)
            |> assets.add("123456789", "other_token", 1),
        ),
      },
    }
  minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test wrong_burned_amount() {
  let ctx = test_utils.mk_mp_script_context()

  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        mint: assets.to_minted_value(
          assets.from_asset(mocks.bounty_id_policy, mocks.bounty_id_name, -1234),
        ),
      },
    }
  !minting_policy(mocks.settings_nft_policy, wrong_ctx)
}

test invalid_script_output_address() {
  let ctx = test_utils.mk_mp_script_context()

  expect Some(outputs) = list.tail(ctx.transaction.outputs)
  let wrong_bounty = {
    expect Some(bounty_utxo) = list.head(ctx.transaction.outputs)
    Output {
      ..bounty_utxo,
      address: Address {
        payment_credential: Script("addr_test"),
        stake_credential: None,
      },
    }
  }
  let wrong_ctx =
    ScriptContext {
      ..ctx,
      transaction: Transaction {
        ..ctx.transaction,
        outputs: list.push(outputs, wrong_bounty),
      },
    }
  !minting_policy(mocks.settings_nft_policy, wrong_ctx)
}
