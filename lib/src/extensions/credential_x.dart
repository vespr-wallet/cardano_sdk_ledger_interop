
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension CredentialX on Credential {
  ParsedCredential toParsedCredential({
    required int accountIndex,
    required int addressIndex,
    required ShelleyAddressRole role,
    required String walletCredsHex,
  }) =>
      switch (type) {
        CredType.ADDR_KEY_HASH => vKeyHash.hexEncode() == walletCredsHex
            ? ParsedCredential.keyPath(
                path: LedgerSigningPath.shelley(
                  account: accountIndex,
                  address: addressIndex,
                  role: role,
                ),
              )
            : ParsedCredential.keyHash(
                keyHashHex: vKeyHash.hexEncode(),
              ),
        CredType.SCRIPT_HASH => ParsedCredential.scriptHash(
            scriptHashHex: vKeyHash.hexEncode(),
          ),
      };
}
