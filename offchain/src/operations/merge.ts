import { buildGithoneyMintingPolicy, buildGithoneyValidator } from "../scripts";
import { MIN_ADA, NetConfig } from "../constants";
import { Data, fromText, toUnit } from "lucid-cardano";

async function mergeBounty(maintainerAddr: string, netConfig: NetConfig) {
  console.debug("START mergeBounty");
  const lucid = netConfig.lucidAdmin!;
  const gitHoneyValidator = buildGithoneyValidator();
  const validatorAddress = lucid.utils.validatorToAddress(gitHoneyValidator);
  const utxo = (await lucid.wallet.getUtxos())[0];
  const outRef = { txHash: utxo.txHash, outputIndex: utxo.outputIndex };
  const mintingScript = buildGithoneyMintingPolicy(outRef);
  const mintingPolicyid = lucid.utils.mintingPolicyToId(mintingScript);
  const githoneyUnit = toUnit(mintingPolicyid, fromText("githoney"));

  // Your code here

  console.debug("END mergeBounty");
  return {
    // Your return object here
  };
}

export default mergeBounty;
