import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../types.dart";

extension RequiredSignersX on RequiredSigners {
  List<ParsedRequiredSigner> toParsedRequiredSigners({
    required Map<CredentialsHex, LedgerSigningPath> derivedCredsToSigningPath,
  }) {
    return signersBytes
        .map(
          (signer) => signer.toParsedRequiredSigner(derivedCredsToSigningPath: derivedCredsToSigningPath),
        )
        .toList();
  }
}

extension _Uint8ListX on Uint8List {
  ParsedRequiredSigner toParsedRequiredSigner({
    required Map<CredentialsHex, LedgerSigningPath> derivedCredsToSigningPath,
  }) {
    final thisHash = hexEncode();
    final signingPath = derivedCredsToSigningPath[thisHash];
    return signingPath != null
        ? ParsedRequiredSigner.path(path: signingPath)
        : ParsedRequiredSigner.hash(hashHex: thisHash);
  }
}
