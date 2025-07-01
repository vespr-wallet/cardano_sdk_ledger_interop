// ignore_for_file: invalid_annotation_target

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
import "package:meta/meta.dart";

@immutable
class SignatureRequestData {
  final ParsedSigningRequest ledgerSignRequest;
  final CardanoPubAccount ledgerPubAccount;

  const SignatureRequestData({
    required this.ledgerSignRequest,
    required this.ledgerPubAccount,
  });

  @override
  String toString() {
    return "SignatureRequestData(ledgerSignRequest: $ledgerSignRequest, ledgerPubAccount: $ledgerPubAccount)";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SignatureRequestData &&
            (identical(other.ledgerSignRequest, ledgerSignRequest) || other.ledgerSignRequest == ledgerSignRequest) &&
            (identical(other.ledgerPubAccount, ledgerPubAccount) || other.ledgerPubAccount == ledgerPubAccount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ledgerSignRequest, ledgerPubAccount);
}
