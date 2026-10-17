// AddressType is the ledger_cardano_plus enum: its value is the Shelley address header type nibble
import "package:cardano_dart_types/cardano_dart_types.dart" hide AddressType;
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
    final destinationAddressHex = output.address.hexValue;
    final destinationCardanoAddress = CardanoAddress.fromHexString(destinationAddressHex);

    final destinationCredentials = destinationCardanoAddress.credentials;
    final destinationStakeCredentialsHex = destinationCardanoAddress.stakeCredentials;
    final maybeDestinationPath =
        paymentCredsToSigningPath[destinationCredentials] ?? changeCredsToSigningPath[destinationCredentials];

    // The device rebuilds a device-owned address from the params, so the params must describe the exact address type.
    // Only base key/key and enterprise key addresses have params we can derive; anything else that still has our
    // payment key (base key/script, pointer) is forwarded verbatim as third party. Unassigned header types are null.
    // ponytail: map basePaymentKeyStakeScript / pointerKey to their params if a wallet ever derives such addresses.
    final headerType = destinationCardanoAddress.bytes.first >> 4;
    final addressType = AddressType.values.where((type) => type.value == headerType).firstOrNull;
    final destination = switch ((maybeDestinationPath, addressType, destinationStakeCredentialsHex)) {
      (final path?, AddressType.basePaymentKeyStakeKey, final stakeHex?) => ParsedOutputDestination.deviceOwned(
          addressParams: ParsedAddressParams.shelley(
            shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
              spendingDataSource: SpendingDataSourcePath(path: path),
              stakingDataSource: stakingCredentialsHex == stakeHex
                  ? StakingDataSource.keyPath(
                      path:
                          LedgerSigningPath.shelley(account: accountIndex, address: 0, role: ShelleyAddressRole.stake),
                    )
                  : StakingDataSource.keyHash(keyHashHex: stakeHex),
            ),
          ),
        ),
      (final path?, AddressType.enterpriseKey, _) => ParsedOutputDestination.deviceOwned(
          addressParams: ParsedAddressParams.shelley(
            shelleyAddressParams: ShelleyAddressParamsData.enterpriseKey(
              spendingDataSource: SpendingDataSourcePath(path: path),
            ),
          ),
        ),
      _ => ParsedOutputDestination.thirdParty(addressHex: destinationAddressHex),
    };

    final tokenBundle = output.value.multiAssets
        .map((multiAsset) => ParsedAssetGroup(
              policyIdHex: multiAsset.policyId.hexValue,
              tokens: multiAsset.assets
                  .map((asset) => ParsedToken(
                        assetNameHex: asset.assetName.hexValue,
                        amount: asset.value.toBigInt(),
                      ))
                  .toList(),
            ))
        .toList();

    return switch (output) {
      CardanoTransactionOutput_Legacy() => ParsedOutput.alonzo(
          destination: destination,
          amount: output.value.lovelace.toBigInt(),
          tokenBundle: tokenBundle,
          datumHashHex: output.outDatumHash?.toParsedDatumHash(),
        ),
      CardanoTransactionOutput_PostAlonzo() => ParsedOutput.babbage(
          destination: destination,
          amount: output.value.lovelace.toBigInt(),
          tokenBundle: tokenBundle,
          datum: output.datum?.toParsedDatum(),
          referenceScriptHex: output.scriptRef?.hexEncode(),
        ),
    };
  }
}
