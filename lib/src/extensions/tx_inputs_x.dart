import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../types.dart";
import "tx_input_x.dart";

extension CardanoTransactionInputListX on CardanoTransactionInputs {
  List<ParsedInput> toParsedInputs({
    required Map<UtxoAndIndex, LedgerSigningPath> inputUtxoToSigningPath,
  }) =>
      data //
          .map((input) => input.toParsedInput(inputUtxoToSigningPath: inputUtxoToSigningPath))
          .toList();
}
