import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

// const timeout = Timeout(Duration(hours: 24));
const timeout = Timeout(Duration(seconds: 10));

// run with "flutter test" command
void main() async {
  const xPubBech32 =
      "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0";
  final ledgerPubAccount = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);


}
