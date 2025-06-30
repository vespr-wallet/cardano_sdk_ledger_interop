import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension MultiAssetListX on List<MultiAsset> {
  List<ParsedAssetGroup> toParsedAssetGroups() {
    return map((multiAsset) => multiAsset.toParsedAssetGroup()).toList();
  }
}

extension MultiAssetX on MultiAsset {
  ParsedAssetGroup toParsedAssetGroup() {
    return ParsedAssetGroup(
      policyIdHex: policyId,
      tokens: assets.toParsedTokens(),
    );
  }
}

extension AssetListX on List<Asset> {
  List<ParsedToken> toParsedTokens() {
    return map((asset) => asset.toParsedToken()).toList();
  }
}

extension AssetX on Asset {
  ParsedToken toParsedToken() {
    return ParsedToken(
      assetNameHex: hexName,
      amount: value,
    );
  }
}
