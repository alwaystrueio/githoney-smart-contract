import { describe, it } from "mocha";
import {
  ACCOUNT_ADMIN,
  emulator,
  signAndSubmit,
  newBounty,
  newAssign
} from "./emulatorConfig";
import { Lucid, OutRef } from "lucid-cardano";
import { mergeBounty } from "../src/operations/merge";
import { closeBounty } from "../src/operations/close";
import { expect } from "chai";

const lucid = await Lucid.new(emulator, "Custom");

describe("Close tests", async () => {
  it("Close Bounty After Contributor Assignment", async () => {
    const createTx = await newBounty(lucid);
    const createOutRef: OutRef = { txHash: createTx.txId, outputIndex: 0 };

    const assignTxId = await newAssign(lucid, createOutRef);
    const assignOutRef: OutRef = { txHash: assignTxId.txId, outputIndex: 0 };

    const closeTx = await closeBounty(assignOutRef, lucid);
    emulator.awaitBlock(1);

    lucid.selectWalletFromSeed(ACCOUNT_ADMIN.seedPhrase);
    await signAndSubmit(lucid, closeTx);
  });

  it("Close Bounty Before Contributor Assignment", async () => {
    const createTx = await newBounty(lucid);
    const createOutRef: OutRef = { txHash: createTx.txId, outputIndex: 0 };

    const closeTx = await closeBounty(createOutRef, lucid);
    emulator.awaitBlock(1);

    lucid.selectWalletFromSeed(ACCOUNT_ADMIN.seedPhrase);
    await signAndSubmit(lucid, closeTx);
  });

  it("Close Bounty already merged", async () => {
    try {
      const createTx = await newBounty(lucid);
      const createOutRef: OutRef = { txHash: createTx.txId, outputIndex: 0 };

      const assignTxId = await newAssign(lucid, createOutRef);
      const assignOutRef: OutRef = { txHash: assignTxId.txId, outputIndex: 0 };

      const mergeTx = await mergeBounty(assignOutRef, lucid);
      emulator.awaitBlock(1);

      lucid.selectWalletFromSeed(ACCOUNT_ADMIN.seedPhrase);
      const mergeTxId = await signAndSubmit(lucid, mergeTx);
      const mergeOutRef: OutRef = { txHash: mergeTxId.txId, outputIndex: 0 };

      await closeBounty(mergeOutRef, lucid);
    } catch (e) {
      const error = e as Error;
      expect(error.message).to.equal("Bounty already merged");
      console.log("Error:", error.message);
    }
  });
});
