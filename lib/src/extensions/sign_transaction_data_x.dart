import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "ledger_signing_path_x.dart";

extension SignedTransactionDataX on SignedTransactionData {
  Future<List<WitnessVKey>> witnessesVKey(CardanoPubAccount cardanoPubAcc) => Future.wait(
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
