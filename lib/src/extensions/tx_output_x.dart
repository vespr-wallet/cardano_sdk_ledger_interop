import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../types.dart";
import "output_datum_x.dart";

extension CardanoTransactionOutputListX on List<CardanoTransactionOutput> {
  List<ParsedOutput> toParsedOutputs({
    required Map<CredentialsHex, LedgerSigningPath> paymentCredsToSigningPath,
    required Map<CredentialsHex, LedgerSigningPath> changeCredsToSigningPath,
    required CredentialsHex stakingCredentialsHex,
    required int accountIndex,
  }) =>
      map(
        (output) => output.toParsedOutput(
          paymentCredsToSigningPath: paymentCredsToSigningPath,
          changeCredsToSigningPath: changeCredsToSigningPath,
          stakingCredentialsHex: stakingCredentialsHex,
          accountIndex: accountIndex,
        ),
      ).toList(growable: false);
}

extension CardanoTransactionOutputX on CardanoTransactionOutput {
  ParsedOutput toParsedOutput({
    required Map<CredentialsHex, LedgerSigningPath> paymentCredsToSigningPath,
    required Map<CredentialsHex, LedgerSigningPath> changeCredsToSigningPath,
    required CredentialsHex stakingCredentialsHex,
    required int accountIndex,
  }) {
    final output = this;
    final destinationAddressHex = output.addressBytes.hexEncode();
    final destinationCardanoAddress = CardanoAddress.fromHexString(destinationAddressHex);

    final destinationCredentials = destinationCardanoAddress.credentials;
    final destinationStakeCredentialsHex = destinationCardanoAddress.stakeCredentials;
    final maybeDestinationPath =
        paymentCredsToSigningPath[destinationCredentials] ?? changeCredsToSigningPath[destinationCredentials];

    final destination = maybeDestinationPath != null
        ? ParsedOutputDestination.deviceOwned(
            addressParams: ParsedAddressParams.shelley(
              shelleyAddressParams: destinationStakeCredentialsHex == null
                  ? ShelleyAddressParamsData.enterpriseKey(
                      spendingDataSource: SpendingDataSourcePath(path: maybeDestinationPath),
                    )
                  : ShelleyAddressParamsData.basePaymentKeyStakeKey(
                      spendingDataSource: SpendingDataSourcePath(path: maybeDestinationPath),
                      stakingDataSource: stakingCredentialsHex == destinationStakeCredentialsHex
                          ? StakingDataSource.keyPath(
                              path: LedgerSigningPath.shelley(
                                account: accountIndex,
                                address: 0,
                                role: ShelleyAddressRole.stake,
                              ),
                            )
                          : StakingDataSource.keyHash(keyHashHex: destinationStakeCredentialsHex),
                    ),
            ),
          )
        : ParsedOutputDestination.thirdParty(addressHex: destinationAddressHex);

    final tokenBundle = output.value.multiAssets
        .map((multiAsset) => ParsedAssetGroup(
              policyIdHex: multiAsset.policyId,
              tokens: multiAsset.assets
                  .map((asset) => ParsedToken(
                        assetNameHex: asset.hexName,
                        amount: asset.value,
                      ))
                  .toList(),
            ))
        .toList();

    return switch (output) {
      CardanoTransactionOutput_Legacy() => ParsedOutput.alonzo(
          destination: destination,
          amount: output.value.lovelace,
          tokenBundle: tokenBundle,
          datumHashHex: output.outDatumHash?.toParsedDatumHash(),
        ),
      CardanoTransactionOutput_PostAlonzo() => ParsedOutput.babbage(
          destination: destination,
          amount: output.value.lovelace,
          tokenBundle: tokenBundle,
          datum: output.datum?.toParsedDatum(),
          referenceScriptHex: output.scriptRef?.hexEncode(),
        ),
    };
  }
}
