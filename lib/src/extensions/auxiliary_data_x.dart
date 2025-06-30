import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension AuxiliaryDataX on CBORMetadata {
  ParsedTxAuxiliaryData? toParsedAuxiliaryData() {
    if (value is CborNull) return null;

    return ParsedTxAuxiliaryData.arbitraryHash(
      hashHex: computeBlake2bHash256().hexEncode(),
    );
  }
}
