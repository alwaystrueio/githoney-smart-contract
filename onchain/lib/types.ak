use cardano/address.{Address}
use cardano/assets.{AssetName, PolicyId}

pub type AssetClass {
  policy_id: PolicyId,
  asset_name: AssetName,
}

pub type TokenInfo {
  asset: AssetClass,
  amount: Int,
}

pub type GithoneyContractRedeemers {
  AddRewards
  Assign
  Merge
  Close
  Claim
}

pub type SettingsRedeemers {
  UpdateSettings
  CloseSettings
}

pub type SettingsDatum {
  githoney_address: Address,
  bounty_creation_fee: Int,
  bounty_reward_fee: Int,
}

pub type GithoneyDatum {
  admin_address: Address,
  maintainer_address: Address,
  contributor_address: Option<Address>,
  bounty_reward_fee: Int,
  deadline: Int,
  merged: Bool,
  initial_value: List<TokenInfo>,
}
