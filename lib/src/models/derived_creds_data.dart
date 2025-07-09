import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../../cardano_sdk_ledger_interop.dart";

class DerivedCredsData {
  final CardanoPubAccount cardanoPubAcc;
  final String stakeCredentialsHex;
  final LedgerSigningPath_Shelley stakeSigningPath;
  final String dRepCredentialsHex;
  final LedgerSigningPath_Shelley dRepSigningPath;
  final Map<CredentialsHex, LedgerSigningPath_Shelley> paymentCredsToSigningPath;
  final Map<CredentialsHex, LedgerSigningPath_Shelley> changeCredsToSigningPath;
  final Map<CredentialsHex, LedgerSigningPath_Shelley> derivedCredsToSigningPath;

  const DerivedCredsData({
    required this.cardanoPubAcc,
    required this.stakeCredentialsHex,
    required this.stakeSigningPath,
    required this.dRepCredentialsHex,
    required this.dRepSigningPath,
    required this.paymentCredsToSigningPath,
    required this.changeCredsToSigningPath,
    required this.derivedCredsToSigningPath,
  });
}
