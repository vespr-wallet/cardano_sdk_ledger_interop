import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_sdk_ledger_interop/cardano_sdk_ledger_interop.dart";
import "package:cardano_sdk_ledger_interop/src/extensions/ledger_signing_path_x.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
import "package:test/test.dart";

void main() async {
  const xPubBech32 =
      "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0";
  final pubAccount = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);
  final tx = CardanoTransaction.deserializeFromHex(
    "84a30081825820${"aa" * 32}00018182583900${"11" * 28}${"22" * 28}1a001e8480021a00030d40a0f5f6",
  );
  final paymentPath = LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment);
  SignedTransactionData signed(String txHashHex) => SignedTransactionData(
        txHashHex: txHashHex,
        witnesses: [Witness(path: paymentPath, witnessSignatureHex: "11" * 64)],
        auxiliaryDataSupplement: null,
      );

  test("maps witnesses when the device signed this body", () async {
    final witnesses = await signed(tx.body.blake2bHash256Hex()).witnessesVKey(cardanoPubAcc: pubAccount, tx: tx);
    final paymentKey = await pubAccount.rolePublicKey(Bip32KeyRole.payment, 0);
    expect(witnesses.single.vkey, paymentKey.rawKey.toUint8List());
    expect(witnesses.single.signature, ("11" * 64).hexDecode());
  });

  test("throws when the device signed a different body hash", () {
    expect(
      () => signed("00" * 32).witnessesVKey(cardanoPubAcc: pubAccount, tx: tx),
      throwsA(isA<InvalidTransactionError>()),
    );
  });

  test("Byron witness paths are rejected", () {
    expect(
      LedgerSigningPath.byron(account: 0, address: 0).vkeyHashBySigningPath(pubAccount),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
