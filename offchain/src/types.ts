import { Constr, Data, fromText } from "lucid-txpipe";

// Aiken types

const AssetClass = Data.Object({
  policy_id: Data.Bytes(),
  asset_name: Data.Bytes()
});
type AssetClassT = Data.Static<typeof AssetClass>;

const WalletSchema = Data.Object({
  paymentKey: Data.Bytes(),
  stakeKey: Data.Nullable(Data.Bytes())
});

type WalletT = Data.Static<typeof WalletSchema>;

const DatumSchema = Data.Object({
  admin: WalletSchema,
  maintainer: WalletSchema,
  contributor: Data.Nullable(WalletSchema),
  bounty_reward_fee: Data.Integer(),
  deadline: Data.Integer(),
  merged: Data.Boolean(),
  initial_value: Data.Array(
    Data.Object({ asset: AssetClass, amount: Data.Integer({ minimum: 0 }) })
  )
});

type GithoneyDatumT = Data.Static<typeof DatumSchema>;
const GithoneyDatum = DatumSchema as unknown as GithoneyDatumT;

function mkDatum(params: {
  admin: WalletT;
  maintainer: WalletT;
  contributor: WalletT | null;
  bounty_reward_fee: bigint;
  deadline: bigint;
  merged: boolean;
  initial_value: Array<{ asset: AssetClassT; amount: bigint }>;
}): string {
  const d: GithoneyDatumT = {
    admin: params.admin,
    maintainer: params.maintainer,
    contributor: params.contributor,
    bounty_reward_fee: params.bounty_reward_fee,
    deadline: params.deadline,
    merged: params.merged,
    initial_value: params.initial_value
  };
  const datum = Data.to<GithoneyDatumT>(d, GithoneyDatum);
  return datum;
}

const multiValWrapper = (
  val_index: number,
  redeemer_index: number,
  params: Data[]
) => Data.to(new Constr(val_index, [new Constr(redeemer_index, params)]));

// eslint-disable-next-line @typescript-eslint/no-namespace
namespace GithoneyValidatorRedeemer {
  export const AddRewards = () => multiValWrapper(1, 0, []);
  export const Assign = () => multiValWrapper(1, 1, []);
  export const Merge = () => multiValWrapper(1, 2, []);
  export const Close = () => multiValWrapper(1, 3, []);
  export const Claim = () => multiValWrapper(1, 4, []);
  export const Mint = () => multiValWrapper(0, 0, []);
}

const SettingsDatumSchema = Data.Object({
  githoney_address: WalletSchema,
  creation_fee: Data.Integer(),
  reward_fee: Data.Integer()
});

type SettingsDatumT = Data.Static<typeof SettingsDatumSchema>;
const SettingsDatum = SettingsDatumSchema as unknown as SettingsDatumT;

function mkSettingsDatum(params: {
  githoneyWallet: WalletT;
  creationFee: bigint;
  rewardFee: bigint;
}): string {
  const d: SettingsDatumT = {
    githoney_address: params.githoneyWallet,
    creation_fee: params.creationFee,
    reward_fee: params.rewardFee
  };
  const datum = Data.to<SettingsDatumT>(d, SettingsDatum);
  return datum;
}

const SettingsRedeemerSchema = Data.Enum([
  Data.Literal("UpdateSettings"),
  Data.Literal("CloseSettings")
]);

type SettingsRedeemerT = Data.Static<typeof SettingsRedeemerSchema>;

// eslint-disable-next-line @typescript-eslint/no-namespace
namespace SettingsRedeemer {
  export const Update = () =>
    Data.to(
      "UpdateSettings",
      SettingsRedeemerSchema as unknown as SettingsRedeemerT
    );

  export const Close = () =>
    Data.to(
      "CloseSettings",
      SettingsRedeemerSchema as unknown as SettingsRedeemerT
    );
}

const BadgeDatumSchema = Data.Object({
  metadata: Data.Map(Data.Bytes(), Data.Bytes()),
  version: Data.Integer()
});

type BadgeDatumT = Data.Static<typeof BadgeDatumSchema>;
const BadgeDatum = BadgeDatumSchema as unknown as BadgeDatumT;

interface Metadata {
  name: string;
  logo: string;
  description: string;
}

const mkBadgeDatum = (metadata: Metadata, version: bigint) => {
  const hexMetadata: [string, string][] = Object.entries(metadata).map(
    ([key, value]) => [fromText(key), fromText(value)]
  );
  const mapMetadata = new Map<string, string>(hexMetadata);
  const datum: BadgeDatumT = {
    metadata: mapMetadata,
    version: version
  };
  return Data.to<BadgeDatumT>(datum, BadgeDatum);
};

export {
  mkDatum,
  mkBadgeDatum,
  mkSettingsDatum,
  SettingsDatumT,
  GithoneyDatumT,
  SettingsDatum,
  GithoneyDatum,
  GithoneyValidatorRedeemer,
  SettingsRedeemer,
  WalletSchema,
  WalletT,
  AssetClass,
  AssetClassT,
  Metadata,
  BadgeDatum
};
