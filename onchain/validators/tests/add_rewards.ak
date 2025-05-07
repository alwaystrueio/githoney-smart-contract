use aiken/collection/list.{foldl, head}
use cardano/assets.{add}
use cardano/transaction.{Output, ScriptContext, Transaction}
use mocks.{token_a_policy, token_b_policy, token_c_policy}
use test_utils.{
  change_output_value, change_script_upper_bound, mk_transition_script_context,
  script_input_without_bounty_id_token,
}
use types.{AddRewards, GithoneyDatum}
use utils.{to_githoney_datum}
use validations

fn tokens_value(value: value.Value) -> value.Value {
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
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_output) = head(script_ctx.transaction.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let script_ctx = change_output_value(script_ctx, 0, script_output_value)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  validations.add_rewards(datum, script_ctx)
}

test without_new_rewards() {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  !validations.add_rewards(datum, script_ctx)
}

test bad_datum() {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let bad_datum = GithoneyDatum { ..datum, merged: True }
  !validations.add_rewards(bad_datum, script_ctx)
}

test after_deadline() {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_output) = head(script_ctx.transaction.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)

  let script_ctx = change_output_value(script_ctx, 0, script_output_value)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let script_ctx = change_script_upper_bound(script_ctx, datum.deadline + 1)
  !validations.add_rewards(datum, script_ctx)
}

test without_bounty_id_token() fail {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_output) = head(script_ctx.transaction.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let script_ctx =
    script_ctx
      |> change_output_value(0, script_output_value)
      |> script_input_without_bounty_id_token()
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  validations.add_rewards(datum, script_ctx)
}

test already_merged_datum() {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_output) = head(script_ctx.transaction.outputs)
  let script_output_value =
    script_output.value |> add(mocks.token_b_policy, mocks.token_b_name, 10000)
  let script_ctx = change_output_value(script_ctx, 0, script_output_value)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  let bad_datum = GithoneyDatum { ..datum, merged: True }

  !validations.add_rewards(bad_datum, script_ctx)
}

test too_many_tokens() {
  let script_ctx = mk_transition_script_context(AddRewards)
  expect Some(script_output) = head(script_ctx.transaction.outputs)
  let script_output_value = script_output.value |> tokens_value
  let script_ctx = change_output_value(script_ctx, 0, script_output_value)
  expect Some(script_input) = head(script_ctx.transaction.inputs)
  let datum: GithoneyDatum = to_githoney_datum(script_input.output.datum)
  !validations.add_rewards(datum, script_ctx)
}
