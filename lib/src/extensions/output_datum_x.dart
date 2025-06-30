import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension OutputDatumHashX on OutputDatum_Hash {
  ParsedDatumHash toParsedDatumHash() => ParsedDatumHash(
        datumHashHex: datumHash.hexEncode(),
      );
}

extension OutputDatumX on OutputDatum {
  ParsedDatum toParsedDatum() => switch (this) {
        OutputDatum_Hash(datumHash: final datumHash) => ParsedDatum.hash(
            datumHashHex: datumHash.hexEncode(),
          ),
        OutputDatum_Inline(plutusData: final plutusData) => ParsedDatum.inline(
            datumHex: switch (plutusData) {
              PlutusData_DefiniteBytes() => plutusData.bytes.hexEncode(),
              // I don't think below implementation would work for indefinite bytes
              //    not sure if it's meant to be supported
              // PlutusData_IndefiniteBytes() => plutusData.bytesList.fold(
              //     <int>[],
              //     (previousValue, element) => [...previousValue, ...element],
              //   ).hexEncode(),
              PlutusData_IndefiniteBytes() => throw UnimplementedError(),
              PlutusData_BigInt() => throw UnimplementedError(),
              PlutusData_Constr() => throw UnimplementedError(),
              PlutusData_List() => throw UnimplementedError(),
              PlutusData_Map() => throw UnimplementedError(),
            },
          ),
      };
}
