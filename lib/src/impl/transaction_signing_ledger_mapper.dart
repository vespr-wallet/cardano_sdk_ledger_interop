import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../../cardano_sdk_ledger_interop.dart";
import "../extensions/auxiliary_data_x.dart";
import "../extensions/certificate_x.dart";
import "../extensions/multi_asset_x.dart";
import "../extensions/required_signer_x.dart";
import "../extensions/tx_inputs_x.dart";
import "../extensions/tx_output_x.dart";
import "../extensions/voting_procedures_x.dart";
import "../extensions/withdrawal_x.dart";
import "../utils/derivation_utils.dart";
import "../utils/signing_mode_utils.dart";

class TransactionSigningLedgerMapper {
  const TransactionSigningLedgerMapper();

  Future<SignatureRequestData> toLedgerSigningRequest({
    required CardanoTransaction tx,
    required NetworkId networkId,
    required String xPubBech32,
    required int accountIndex,
    // Ideally this maxDeriveAddressCount should be based on the payment creds observed on chain
    required int maxDeriveAddressCount,
    required Map<UtxoAndIndex, Bech32OrBase58CardanoAddress> inputUtxoToAddress,
  }) async {
    final body = tx.body;
    final auxiliaryData = tx.auxiliaryData;

    final credsData = await DerivationUtils.deriveCredsToSigningPath(
      xPubBech32: xPubBech32,
      accountIndex: accountIndex,
      maxDeriveAddressCount: maxDeriveAddressCount,
    );

    final derivedCredsToSigningPath = credsData.derivedCredsToSigningPath;
    final stakeCredentialsHex = credsData.stakeCredentialsHex;
    final cardanoPubAcc = credsData.cardanoPubAcc;
    final paymentCredsToSigningPath = credsData.paymentCredsToSigningPath;
    final changeCredsToSigningPath = credsData.changeCredsToSigningPath;

    final Map<UtxoAndIndex, LedgerSigningPath> inputUtxoToSigningPath = Map.fromEntries(
      inputUtxoToAddress.entries.map((entry) {
        final utxoAndIndex = entry.key;
        final addressBech32 = entry.value;
        final creds = CardanoAddress.fromBech32OrBase58(addressBech32).credentials;

        // No match means it's an external address
        final maybePath = derivedCredsToSigningPath[creds];
        if (maybePath == null) return null;

        return MapEntry(utxoAndIndex, maybePath);
      }).nonNulls,
    );

    final parsedCertificates = body.certs?.certificates
        .map(
          (e) => e.toParsedCertificate(
            accountIndex: accountIndex,
            stakeCredsHex: stakeCredentialsHex,
            dRepKeyHashHex: cardanoPubAcc.dRepDerivation.value.credentialsHex,
            coldCredentialKeyHashHex: cardanoPubAcc.constitutionalCommitteeColdDerivation.value.hexCredential,
            hotCredentialKeyHashHex: cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCredential,
          ),
        )
        .toList(growable: false);

    final parsedInputs = body.inputs.toParsedInputs(
      inputUtxoToSigningPath: inputUtxoToSigningPath,
    );
    final parsedOutputs = body.outputs.toParsedOutputs(
      paymentCredsToSigningPath: paymentCredsToSigningPath,
      changeCredsToSigningPath: changeCredsToSigningPath,
      stakingCredentialsHex: stakeCredentialsHex,
      accountIndex: accountIndex,
    );

    final parsedCollateralInputs = body.collateral?.toParsedInputs(inputUtxoToSigningPath: inputUtxoToSigningPath);
    final parsedWithdrawals = body.withdrawals?.toParsedWithdrawals(
      walletStakeCredsHex: stakeCredentialsHex,
      accountIndex: accountIndex,
    );
    final parsedVoterVotes = body.votingProcedures?.toParsedVoterVotes(
      accountIndex: accountIndex,
      dRepKeyHashHex: cardanoPubAcc.dRepDerivation.value.credentialsHex,
      hotCredentialKeyHashHex: cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCredential,
      // TODOpoolKeyHashHex
      poolKeyHashHex: "TODO: UNSUPORTED YET",
    );

    final signingMode = determineSigningMode(
      parsedCertificates: parsedCertificates,
      stakeCredentialsHex: stakeCredentialsHex,
      inputs: parsedInputs,
      outputs: parsedOutputs,
      withdrawals: body.withdrawals,
      collateralInputs: parsedCollateralInputs,
      mint: body.mint,
      requiredSigners: body.requiredSigners,
      scriptDataHash: body.scriptDataHash,
      votingProcedures: parsedVoterVotes,
    );

    final parsedRequiredSigners = body.requiredSigners?.toParsedRequiredSigners(
      derivedCredsToSigningPath: derivedCredsToSigningPath,
    );

    final parsedTransaction = ParsedTransaction(
      network: switch (body.networkId ?? networkId) {
        NetworkId.mainnet => CardanoNetwork.mainnet(),
        NetworkId.testnet => CardanoNetwork.preprod(),
      },
      inputs: parsedInputs,
      outputs: parsedOutputs,
      fee: body.fee,
      ttl: body.ttl,
      certificates: parsedCertificates,
      withdrawals: parsedWithdrawals,
      auxiliaryData: auxiliaryData?.toParsedAuxiliaryData(),
      validityIntervalStart: body.validityStartInterval,
      mint: body.mint?.toParsedAssetGroups(),
      scriptDataHashHex: body.scriptDataHash?.toScriptDataHash(),
      collateralInputs: parsedCollateralInputs,
      requiredSigners: parsedRequiredSigners,
      includeNetworkId: body.networkId != null,
      collateralOutput: body.collateralReturn?.toParsedOutput(
        paymentCredsToSigningPath: paymentCredsToSigningPath,
        changeCredsToSigningPath: changeCredsToSigningPath,
        stakingCredentialsHex: stakeCredentialsHex,
        accountIndex: accountIndex,
      ),
      totalCollateral: body.totalCollateral,
      votingProcedures: parsedVoterVotes,
      donation: body.donation?.toBigInt(),
      treasury: body.currentTreasuryValue?.toBigInt(),
      referenceInputs: body.referenceInputs?.toParsedInputs(inputUtxoToSigningPath: inputUtxoToSigningPath),
    );

    /**
     * If true, serialize transactions with 258 tags for all sets (optional since Conway).
     * If false or not given, do not use the tags.
     */
    final options = ParsedTransactionOptions(
      tagCborSets: body.inputs.cborTags.contains(258),
    );

    final ledgerSignRequest = ParsedSigningRequest(
      tx: parsedTransaction,
      signingMode: signingMode,
      additionalWitnessPaths: parsedRequiredSigners //
              ?.whereType<RequiredSignerPath>()
              .map((e) => e.path)
              .toList() ??
          [],
      options: options,
    );

    return SignatureRequestData(
      ledgerSignRequest: ledgerSignRequest,
      ledgerPubAccount: cardanoPubAcc,
    );
  }
}

extension ShelleyTransactionMapper on CardanoTransaction {
  @Deprecated("Use TransactionSigningLedgerMapper class instead to allow mocking for tests")
  Future<SignatureRequestData> toLedgerSigningRequest({
    required NetworkId networkId,
    required String xPubBech32,
    required int accountIndex,
    // Ideally this maxDeriveAddressCount should be based on the payment creds observed on chain
    required int maxDeriveAddressCount,
    required Map<UtxoAndIndex, Bech32OrBase58CardanoAddress> inputUtxoToAddress,
  }) =>
      const TransactionSigningLedgerMapper().toLedgerSigningRequest(
        tx: this,
        networkId: networkId,
        xPubBech32: xPubBech32,
        accountIndex: accountIndex,
        maxDeriveAddressCount: maxDeriveAddressCount,
        inputUtxoToAddress: inputUtxoToAddress,
      );
}

extension _Uint8ListX on Uint8List {
  ScriptDataHash toScriptDataHash() => ScriptDataHash(hexString: hexEncode());
}
