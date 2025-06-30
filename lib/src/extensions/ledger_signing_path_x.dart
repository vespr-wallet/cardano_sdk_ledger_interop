import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "shelley_address_role_x.dart";

extension LedgerSigningPathX on LedgerSigningPath {
  Future<Uint8List> vkeyHashBySigningPath(
    CardanoPubAccount cardanoPubAcc,
  ) async {
    final path = this;

    return switch (path) {
      LedgerSigningPath_Shelley() => (await cardanoPubAcc.rolePublicKey(path.role.bip32KeyRole, path.address)) //
          .rawKey
          .toUint8List(),
      LedgerSigningPath_Byron() => (await cardanoPubAcc.rolePublicKey(Bip32KeyRole.payment, path.address)) //
          .rawKey
          .toUint8List(),
      LedgerSigningPath_CIP36() => throw UnimplementedError(),
      LedgerSigningPath_Custom() => throw UnimplementedError(),
    };
  }
}
