import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../../cardano_sdk_ledger_interop.dart";
import "../models/derived_creds_data.dart";

class DerivationUtils {
  const DerivationUtils._();

  static Future<DerivedCredsData> deriveCredsToSigningPath({
    required String xPubBech32,
    required int accountIndex,
    required int maxDeriveAddressCount,
  }) async {
    final CardanoPubAccount cardanoPubAcc = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);
    final String stakeCredentialsHex = await cardanoPubAcc.stakeCredentialsHex();

    final [paymentCreds, changeCreds] = await Future.wait([
      cardanoPubAcc.deriveCredentialsHex(
        startIndex: 0,
        endIndex: maxDeriveAddressCount,
        role: Bip32KeyRole.payment,
      ),
      cardanoPubAcc.deriveCredentialsHex(
        startIndex: 0,
        endIndex: maxDeriveAddressCount,
        role: Bip32KeyRole.change,
      ),
    ]);

    final Map<CredentialsHex, LedgerSigningPath_Shelley> paymentCredsToSigningPath = Map.fromEntries(
      paymentCreds.indexed.map(
        (indexAndCred) => MapEntry(
          indexAndCred.$2,
          LedgerSigningPath_Shelley(
            account: accountIndex,
            address: indexAndCred.$1,
            role: ShelleyAddressRole.payment,
          ),
        ),
      ),
    );

    final Map<CredentialsHex, LedgerSigningPath_Shelley> changeCredsToSigningPath = Map.fromEntries(
      changeCreds.indexed.map(
        (indexAndCred) => MapEntry(
          indexAndCred.$2,
          LedgerSigningPath_Shelley(
            account: accountIndex,
            address: indexAndCred.$1,
            role: ShelleyAddressRole.change,
          ),
        ),
      ),
    );

    final stakeSigningPath = LedgerSigningPath_Shelley(
      account: accountIndex,
      address: 0,
      role: ShelleyAddressRole.stake,
    );

    final dRepSigningPath = LedgerSigningPath_Shelley(
      account: accountIndex,
      address: 0,
      role: ShelleyAddressRole.drepCredential,
    );

    // Should contain creds of all derivations
    final Map<CredentialsHex, LedgerSigningPath_Shelley> derivedCredsToSigningPath = {
      ...paymentCredsToSigningPath,
      ...changeCredsToSigningPath,
      // Credentials in HEX
      stakeCredentialsHex: stakeSigningPath,
      cardanoPubAcc.dRepDerivation.value.credentialsHex: dRepSigningPath,
      cardanoPubAcc.constitutionalCommitteeColdDerivation.value.hexCredential: LedgerSigningPath_Shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeCold,
      ),
      cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCredential: LedgerSigningPath_Shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeHot,
      ),
      // Raw Keys in HEX || NOT SURE IF WE ACTUALLY NEED THOSE HERE
      // -- I think on-chain we'll only see the hex credentials, not the vkey
      cardanoPubAcc.stakeKey.rawKey.hexEncode(): stakeSigningPath,
      cardanoPubAcc.dRepDerivation.value.dRepKeyHex: dRepSigningPath,
      cardanoPubAcc.constitutionalCommitteeColdDerivation.value.hexCCKey: LedgerSigningPath_Shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeCold,
      ),
      cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCCKey: LedgerSigningPath_Shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeHot,
      ),
    };

    return DerivedCredsData(
      cardanoPubAcc: cardanoPubAcc,
      stakeCredentialsHex: stakeCredentialsHex,
      stakeSigningPath: derivedCredsToSigningPath[stakeCredentialsHex]!,
      dRepCredentialsHex: cardanoPubAcc.dRepDerivation.value.credentialsHex,
      dRepSigningPath: derivedCredsToSigningPath[cardanoPubAcc.dRepDerivation.value.credentialsHex]!,
      paymentCredsToSigningPath: paymentCredsToSigningPath,
      changeCredsToSigningPath: changeCredsToSigningPath,
      derivedCredsToSigningPath: derivedCredsToSigningPath,
    );
  }
}
