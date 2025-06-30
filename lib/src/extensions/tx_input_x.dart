import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../types.dart";

extension CardanoTransactionInputX on CardanoTransactionInput {
  ParsedInput toParsedInput({
    required Map<UtxoAndIndex, LedgerSigningPath> inputUtxoToSigningPath,
  }) {
    final signingPath = inputUtxoToSigningPath["$transactionHash#$index"];

    return ParsedInput(
      txHashHex: transactionHash,
      outputIndex: index,
      path: signingPath,
    );
  }
}
