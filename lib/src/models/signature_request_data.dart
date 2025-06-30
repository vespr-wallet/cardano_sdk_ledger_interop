// ignore_for_file: invalid_annotation_target

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

part "signature_request_data.freezed.dart";

@freezed
sealed class SignatureRequestData with _$SignatureRequestData {
  const factory SignatureRequestData({
    required ParsedSigningRequest ledgerSignRequest,
    required CardanoPubAccount ledgerPubAccount,
  }) = _SignatureRequestData;
  const SignatureRequestData._();
}
