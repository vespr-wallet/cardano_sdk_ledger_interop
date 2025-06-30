sealed class CardanoLedgerInteropError implements Exception {
  final String message;

  CardanoLedgerInteropError(this.message);

  @override
  String toString() {
    // ignore: no_runtimetype_tostring
    return "CardanoLedgerInteropError-$runtimeType:  $message";
  }
}

class NotSupportedError extends CardanoLedgerInteropError {
  NotSupportedError(super.message);
}

class InvalidTransactionError extends CardanoLedgerInteropError {
  InvalidTransactionError(super.message);
}
