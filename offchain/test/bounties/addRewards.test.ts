import { describe, it } from "mocha";
import { Assets, fromText, OutRef, toUnit } from "lucid-txpipe";
import {
  deployUtxo,
  newAssign,
  newBounty,
  newMerge,
  signAndSubmit
} from "../utils";
import {
  ACCOUNT_0,
  emulator,
  tokenAUnit,
  lucid,
  tokens,
  ACCOUNT_MANTAINER
} from "../emulatorConfig";
import { addRewards } from "../../src/operations/bounties/addRewards";
import { expect } from "chai";
import logger from "../../src/logger";

describe("Add Rewards tests", async () => {
  it("Add Rewards with same token", async () => {
    const { settingsUtxo } = await deployUtxo(lucid);
    const createTxIdId = await newBounty(lucid, settingsUtxo);

    const bountyOutRef: OutRef = { txHash: createTxIdId, outputIndex: 0 };
    const reward = {
      lovelace: 50n
    };
    const addRewardsTx = await addRewards(
      settingsUtxo,
      bountyOutRef,
      ACCOUNT_0.address,
      reward,
      lucid
    );
    emulator.awaitBlock(3);

    lucid.selectWalletFromSeed(ACCOUNT_0.seedPhrase);
    await signAndSubmit(lucid, addRewardsTx);
  });

  it("Add Rewards with different token", async () => {
    const { settingsUtxo } = await deployUtxo(lucid);
    const createTxIdId = await newBounty(lucid, settingsUtxo);

    const bountyOutRef: OutRef = { txHash: createTxIdId, outputIndex: 0 };
    const reward = {
      [tokenAUnit]: 75n
    };
    const addRewardsTx = await addRewards(
      settingsUtxo,
      bountyOutRef,
      ACCOUNT_0.address,
      reward,
      lucid
    );
    emulator.awaitBlock(3);

    lucid.selectWalletFromSeed(ACCOUNT_0.seedPhrase);
    await signAndSubmit(lucid, addRewardsTx);
  });

  it("Add Rewards with already merged bounty", async () => {
    const { settingsUtxo } = await deployUtxo(lucid);
    try {
      const createTxId = await newBounty(lucid, settingsUtxo);
      const createOutRef: OutRef = { txHash: createTxId, outputIndex: 0 };

      const assignTxId = await newAssign(lucid, createOutRef, settingsUtxo);
      const assignOutRef: OutRef = { txHash: assignTxId, outputIndex: 0 };

      const mergeTxId = await newMerge(lucid, assignOutRef, settingsUtxo);
      const mergeOutRef: OutRef = { txHash: mergeTxId, outputIndex: 0 };

      const reward = {
        [tokenAUnit]: 75n
      };
      await addRewards(
        settingsUtxo,
        mergeOutRef,
        ACCOUNT_0.address,
        reward,
        lucid
      );
    } catch (e) {
      const error = e as Error;
      logger.error(error.message);
      expect(error.message).to.equal("Bounty already merged");
    }
  });

  it("Add Rewards With too many assets", async () => {
    const { settingsUtxo } = await deployUtxo(lucid);
    const createTxIdId = await newBounty(lucid, settingsUtxo);

    const bountyOutRef: OutRef = { txHash: createTxIdId, outputIndex: 0 };
    const reward: Assets = {
      lovelace: 50n
    };
    tokens.forEach((token) => {
      reward[toUnit(token.policy_id, fromText(token.asset_name))] = 1000n;
    });
    try {
      await addRewards(
        settingsUtxo,
        bountyOutRef,
        ACCOUNT_MANTAINER.address,
        reward,
        lucid
      );
    } catch (e) {
      const error = e as Error;
      logger.error(error.message);
      expect(error.message).to.equal("Too many assets, max 15");
    }
  });
});
