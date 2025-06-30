import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension AnchorX on Anchor {
  ParsedAnchor toParsedAnchor() => ParsedAnchor(
        url: anchorUrl,
        hashHex: anchorDataHash.hexEncode(),
      );
}
