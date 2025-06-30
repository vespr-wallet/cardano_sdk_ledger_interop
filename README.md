# Cardano SDK Ledger Interop

[![pub package](https://img.shields.io/pub/v/cardano_sdk_ledger_interop.svg)](https://pub.dev/packages/cardano_sdk_ledger_interop)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Cardano SDK Ledger Interop** is a Dart package that bridges the gap between [cardano_dart_types](https://github.com/vespr-wallet/cardano_dart_types), [cardano_flutter_sdk](https://github.com/vespr-wallet/cardano_flutter_sdk), and [ledger_cardano_plus](https://pub.dev/packages/ledger_cardano_plus). It provides the essential mapping and conversion logic to serialize Cardano transactions and related data structures for use with Ledger hardware wallets.

---

## Overview

When building Cardano applications in Dart/Flutter, you often need to sign transactions with a Ledger device. However, the data models and serialization formats used by the Cardano SDKs differ from those required by Ledger's signing APIs. This package provides the "connective tissue"—it takes transactions and types from the Cardano SDKs and converts them into the specific formats and models required by the Ledger device libraries.

- **Input:** Cardano transaction models from `cardano_flutter_sdk` / `cardano_dart_types`
- **Output:** Data structures and serialization compatible with `ledger_cardano_plus` for secure signing on Ledger devices

---

## Features

- **Transaction Mapping:** Convert Cardano transactions into Ledger-compatible signing requests.
- **Type Conversion:** Map Cardano SDK types (inputs, outputs, certificates, etc.) to Ledger models.
- **Serialization:** Prepare and serialize data for Ledger device communication.
- **Error Handling:** Custom error types for unsupported or invalid transaction scenarios.

---

## Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cardano_sdk_ledger_interop: ^0.5.5
  cardano_flutter_sdk: ^2.5.0
  ledger_cardano_plus: ^0.5.5
  cardano_dart_types: # version as required by cardano_flutter_sdk
```

Then run:

```sh
dart pub get
```

### Usage Example

Here's a minimal example of converting a Cardano transaction to a Ledger signing request:

```dart
import 'package:cardano_dart_types/cardano_dart_types.dart';
import 'package:cardano_sdk_ledger_interop/src/mapper.dart';

void main() async {
  final rawTxHex = '...'; // Your transaction CBOR hex
  final tx = CardanoTransaction.deserializeFromHex(rawTxHex);

  final ledgerRequest = await tx.toLedgerSigningRequest(
    accountIndex: 0,
    inputUtxoToAddress: {
      // Map of UTXO#idx to address
      'txhash#index': 'addr1...',
    },
    maxDeriveAddressCount: 10,
    networkId: NetworkId.mainnet,
    xPubBech32: 'xpub1...',
  );

  print(ledgerRequest);
}
```

For a more complete example, see [`example/hex_tx_to_ledger_example.dart`](example/hex_tx_to_ledger_example.dart).

---

## API

The main entry point is the extension on `CardanoTransaction`:

```dart
Future<SignatureRequestData> toLedgerSigningRequest({
  required NetworkId networkId,
  required String xPubBech32,
  required int accountIndex,
  required int maxDeriveAddressCount,
  required Map<UtxoAndIndex, Bech32OrBase58CardanoAddress> inputUtxoToAddress,
})
```

This produces a `SignatureRequestData` object, which contains all the information needed to sign the transaction on a Ledger device.

### Error Handling

Custom errors are defined in `lib/src/errors/errors.dart`:

- `CardanoLedgerInteropError`
- `NotSupportedError`
- `InvalidTransactionError`

---

## Dependencies

- [cardano_flutter_sdk](https://github.com/vespr-wallet/cardano_flutter_sdk): Cardano SDK for Flutter/Dart.
- [cardano_dart_types](https://github.com/vespr-wallet/cardano_dart_types): Core Cardano data types for Dart.
- [ledger_cardano_plus](https://pub.dev/packages/ledger_cardano_plus): Ledger device communication and models for Cardano.

---

## Contributing

Contributions, issues, and feature requests are welcome! Please open an issue or submit a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Links

- [Cardano Flutter SDK](https://github.com/vespr-wallet/cardano_flutter_sdk)
- [Cardano Dart Types](https://github.com/vespr-wallet/cardano_dart_types)
- [Ledger Cardano Plus](https://pub.dev/packages/ledger_cardano_plus)
- [Cardano Documentation](https://docs.cardano.org/)

---

## Maintainers

- [VESPR Wallet](https://vespr.xyz)

