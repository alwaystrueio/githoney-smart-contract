# Audit Notes

## validators/githoney_contract.ak

### Note 1 (Lines 42-42)

? What if GitHoney closes the settings with open bounties? Can the maintainer/admin get the money back or is it blocked forever? What if the maintainer merges the PR. Can the contributor get the money without settings?

```
      CloseSettings -> close_settings(datum, ctx)
```

### Note 2 (Lines 48-48)

? Could I use it as a different purpose than minting?

```
  fn settings_policy(_redeemer: Redeemer, ctx: ScriptContext) {
```

### Note 3 (Lines 25-25)

? Why is this transaciton necessary? Why not send the rewards to the contributor on Merge and that's it?

```
claim(datum, ctx)
```

### Note 4 (Lines 54-54)

? Are "badges" related policies/validators part of the protocol? How exactly?

```
badges_policy
```

## Project Notes

## lib/checks.ak

### Note 1 (Lines 12-12)

unnecessarily passing all Tx context

```

```

### Note 2 (Lines 33-33)

? Why I don't check admin_wallet?

```
is_utxo_datum_valid
```

### Note 3 (Lines 22-22)

! finding: I can put a dummy token to get a non-zero value while putting less than min_ada of ADA

```
there_are_some_reward
```

### Note 4 (Lines 24-24)

! Checking if the value contains the bounty_id twice.

```
|> merge(from_asset(policy_id, bounty_id, 1))
```

## lib/utils.ak

### Note 1 (Lines 22-22)

get_minting_info ensures only one asset can be minted on the tx

```

```

### Note 2 (Lines 67-67)

? This check should be at the validator level?

```

```

### Note 3 (Lines 77-77)

? Why not use Address to begin with?

```
  let address =
```

### Note 4 (Lines 134-134)

! Update to the latest Aiken version to use the latest stdlib version that has an optimized `match()` function to do this

```
value_grater_than_or_equal(
```

### Note 5 (Lines 125-125)

No single asset class can have less than before

```

```

### Note 6 (Lines 128-128)

Only one assset class has to have more to be True

```

```

### Note 7 (Lines 171-171)

! This is not necessary in the latest Aiken

```
tokens_to_value
```

### Note 8 (Lines 159-159)

? Better to use rationals?

```
 / 
```

### Note 9 (Lines 159-159)

? Why 100*100?

```
( 100 * 100 )
```

## lib/types.ak

### Note 1 (Lines 28-28)

Unnecessary type. `Address` exists

```

```

### Note 2 (Lines 43-43)

? Why do I need to repeat the bounty_reward_fee here? It's already in the SettingsUTxO's datum. Maybe to allow the bounty to keep working if the SettingsUTxO is closed or updated?

```
bounty_reward_fee
```

### Note 3 (Lines 46-46)

Why do I need this initial_value field?

```
initial_value
```

### Note 4 (Lines 45-45)

? Is this field actually necessary?

```
merged: Bool
```

### Note 5 (Lines 40-40)

! Change this to a PKH. It's only used to check if Tx was signed by admin

```
admin_wallet: Wallet
```

## lib/validations.ak

### Note 1 (Lines 243-243)

! this can be pattern-matched directly!

```

```

### Note 2 (Lines 262-262)

? I never check that the policy is actually the one corresponding with the settings_policy(). Would that open an attack vector?

```
  expect [(settings_policy_policy, _, _)] =
```

### Note 3 (Lines 275-275)

Why is the ADA part necessary? the GitHoney Wallet already signs the Tx. Why not just make sure the NFT is burned and that's it?

```
is_githoney_pay_valid
```

### Note 4 (Lines 301-301)

We never check if the address corresponds with the SettingsUTxO validator

```
let script_output = get_first_output(ctx)
```

### Note 5 (Lines 288-288)

Since there's only one AssetClass being burned, and this minting policy is running, we're for sure minting/burning from this policy

```
let (settings_policy, _, minted_quantity) = get_minting_info(ctx.transaction)
```

### Note 6 (Lines 207-207)

? Why allowing the users to pay in multiple UTxOs? Checking for a single value is way cheaper than folding over all outputs!

```
is_creation_fee_paid
```

### Note 7 (Lines 208-208)

! Comparing all assets when we only care about ADA is extremely expensive! Use `lovelace_of()` and compare Int instead

```
value_grater_than_or_equal
```

### Note 8 (Lines 65-65)

? Why is this check needed? We alredy check that the datum is exactly the same as the input UTxO

```
is_datum_not_merged = !datum.merged
```

### Note 9 (Lines 193-193)

! I can choose the `bounty_id`! That means I could create two bounty_utxos with the exact same datum and value!

```
bounty_id,
```

### Note 10 (Lines 56-56)

! This is suceptible to double-satisfaction if the two Bounties are exactly the same. This means:

```
script_output = get_first_output(ctx)
```

### Note 11 (Lines 45-45)

! I think I can create a twin of a Bounty UTxO and use double-satisfaction to extract a bounty_token from the protocol. Is that so? If it is, what can I do with it?

```
is_there_one_bounty_id 
```

### Note 12 (Lines 44-44)

I unnecesarily throw away the amount of tokens to then use the key to look for it again in the next let binding! Pattern-match instead!

```
tokens(bounty_id_policy) |> dict.keys
```

### Note 13 (Lines 48-48)

Wrong statement! This only checks if there's one bountyid_token in this UTxO's value. There could be more in other inputs!

```
fail @"There should be exactly one bounty id token in the inputs"
```

### Note 14 (Lines 82-82)

? Why is it necessary to add min_ada?

```
expected_value = value.merge(script_input.value, from_lovelace(min_ada))
```

### Note 15 (Lines 143-143)

! This code is repeated and should be simplified to reduce code-complexity

```
is_maintainer_pay_valid
```

### Note 16 (Lines 139-139)

I still don't see why we shouldn't assume a single utxo per wallet

```
value_grater_than_or_equal
```

### Note 17 (Lines 135-135)

? If more value was added, where should it go? This doesn't check for that, is that ok?

```
are_payments_valid
```

### Note 18 (Lines 191-191)

! Finding: This should be moved inside the else clause. By putting them here, it makes the burning path overly-restrictive and makes it so, if GitHoney deletes the SettingsUTxO, contributors can't claim their bounties!

```
settings_datum
```

# Reviewed Sections

## validators/githoney_contract.ak

- Lines 47-47
- Lines 49-51
- Lines 34-41
- Lines 43-46
- Lines 42-42
- Lines 21-21
- Lines 22-22
- Lines 24-24
- Lines 23-23
- Lines 25-25
- Lines 26-32
- Lines 14-20

## lib/utils.ak

- Lines 66-72
- Lines 25-37
- Lines 20-24
- Lines 39-42
- Lines 117-132
- Lines 75-96
- Lines 134-136
- Lines 171-184
- Lines 138-169

## lib/checks.ak

- Lines 34-41
- Lines 15-31
- Lines 11-13
- Lines 43-48
- Lines 57-64
- Lines 66-69

## lib/validations.ak

- Lines 191-195
- Lines 199-206
- Lines 209-229
- Lines 233-258
- Lines 260-282
- Lines 284-311
- Lines 23-35
- Lines 37-52
- Lines 54-70
- Lines 72-86
- Lines 130-168
- Lines 88-128
- Lines 170-187
- Lines 196-198
- Lines 190-190

