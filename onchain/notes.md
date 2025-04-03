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

# Reviewed Sections

