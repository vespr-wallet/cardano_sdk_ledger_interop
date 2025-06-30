import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension GovActionIdX on GovActionId {
  ParsedGovActionId toParsedGovActionId() => ParsedGovActionId(
        txHashHex: transactionId,
        govActionIndex: govActionIndex,
      );
}
