import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";


extension DrepX on Drep {
  ParsedDRep toParsedDRep({
    required final String walletDrepKeyHashHex,
    required final int account,
  }) =>
      switch (this) {
        Drep_AddrKeyHash(hash: final keyHashHex) => keyHashHex == walletDrepKeyHashHex
            ? ParsedDRep.keyPath(
                path: LedgerSigningPath.shelley(
                  account: account,
                  address: 0,
                  role: ShelleyAddressRole.drepCredential,
                ),
              )
            : ParsedDRep.keyHash(keyHashHex: keyHashHex),
        Drep_ScriptHash(hash: final scriptHashHex) => ParsedDRep.scriptHash(scriptHashHex: scriptHashHex),
        Drep_Abstain() => ParsedDRep.abstain(),
        Drep_NoConfidence() => ParsedDRep.noConfidence(),
      };
}
