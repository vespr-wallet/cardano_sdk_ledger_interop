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
      LedgerSigningPath_PoolCold() => throw UnsupportedError(
          "Pool cold keys cannot be derived from a Shelley account public key",
        ),
      LedgerSigningPath_Shelley() => (await cardanoPubAcc.rolePublicKey(path.role.bip32KeyRole, path.address)) //
          .rawKey
          .toUint8List(),
      // 44' keys are not children of the 1852' account key; the Shelley payment key here would be the wrong vkey.
      LedgerSigningPath_Byron() => throw UnsupportedError(
          "Byron keys cannot be derived from a Shelley account public key",
        ),
      LedgerSigningPath_CIP36() => throw UnimplementedError(),
      LedgerSigningPath_Custom() => throw UnimplementedError(),
    };
  }
}
