import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../errors/errors.dart";
import "ledger_signing_path_x.dart";

extension SignedTransactionDataX on SignedTransactionData {
  /// The witnesses for [tx]. The returned future fails with [InvalidTransactionError] when the hash the device signed
  /// is not the hash of [tx]'s body as it serializes now, so a witness is never attached to a transaction it does not
  /// sign. The hash is computed fresh: `blake2bHash256Hex()` may return the hash cached at parse time, which
  /// `copyWith` keeps even after the body changed.
  Future<List<WitnessVKey>> witnessesVKey({
    required CardanoPubAccount cardanoPubAcc,
    required CardanoTransaction tx,
  }) async {
    final bodyHashHex = tx.body.computeBlake2bHash256().hexEncode();
    if (txHashHex.toLowerCase() != bodyHashHex) {
      throw InvalidTransactionError("Ledger signed body hash $txHashHex but the transaction body hash is $bodyHashHex");
    }
    return Future.wait(
      witnesses.map(
        (witness) async {
          final vkey = await witness.path.vkeyHashBySigningPath(cardanoPubAcc);
          return WitnessVKey(
            vkey: vkey,
            signature: witness.witnessSignatureHex.hexDecode(),
          );
        },
      ),
    );
  }
}
