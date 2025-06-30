import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../errors/errors.dart";

extension WithdrawalListX on List<Withdraw> {
  List<ParsedWithdrawal> toParsedWithdrawals({
    required String walletStakeCredsHex,
    required int accountIndex,
  }) =>
      map((withdraw) => withdraw.toParsedWithdrawal(
            walletStakeCredsHex: walletStakeCredsHex,
            accountIndex: accountIndex,
          )).toList();
}

extension WithdrawalX on Withdraw {
  ParsedWithdrawal toParsedWithdrawal({
    required String walletStakeCredsHex,
    required int accountIndex,
  }) {
    final destCardanoAddress = CardanoAddress.fromBech32OrBase58(stakeAddressBech32);

    switch (destCardanoAddress) {
      case CardanoAddressByron():
      case CardanoAddressPointer():
      case CardanoAddressBase():
      case CardanoAddressEnterprise():
        throw InvalidTransactionError("Unsupported withdrawal address type: ${destCardanoAddress.runtimeType}");
      case CardanoAddressReward():
        return ParsedWithdrawal(
            amount: coin,
            stakeCredential: switch (destCardanoAddress.credentialsType.value) {
              CredentialType.key => destCardanoAddress.credentials == walletStakeCredsHex
                  ? ParsedCredential.keyPath(
                      path: LedgerSigningPath.shelley(
                        account: accountIndex,
                        address: 0,
                        role: ShelleyAddressRole.stake,
                      ),
                    )
                  : ParsedCredential.keyHash(
                      keyHashHex: destCardanoAddress.credentials,
                    ),
              CredentialType.script => ParsedCredential.scriptHash(
                  scriptHashHex: destCardanoAddress.credentials,
                ),
            });
    }
  }
}
