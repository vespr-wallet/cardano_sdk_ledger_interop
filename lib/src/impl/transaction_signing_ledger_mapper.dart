import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../../cardano_sdk_ledger_interop.dart";
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

    // ParsedTransaction has no proposals field; dropping them would make the device sign a different body
    if (body.proposalProcedures?.isNotEmpty ?? false) {
      throw NotSupportedError("Proposal procedures are not supported for Ledger signing");
    }

    // Ledger takes a single tagCborSets flag for all sets, so mixed encodings can't be reproduced
    final setTags = {
      for (final tags in [
        body.inputs.cborTags,
        body.collateral?.cborTags,
        body.referenceInputs?.cborTags,
        body.certs?.cborTags,
        body.requiredSigners?.cborTags,
      ])
        if (tags != null) tags.contains(258),
    };
    if (setTags.length > 1) {
      throw NotSupportedError("Mixed CBOR set tag (258) encoding is not supported for Ledger signing");
    }

    // Ledger rebuilds the body canonically from the parsed fields (definite lengths, ascending integer map keys),
    // so any other encoding would be signed as different bytes. cardano_dart_types keeps the original encoding.
    if (!tx.hasAscendingBodyKeyOrder) {
      throw NotSupportedError("Transaction body keys are not in ascending order; Ledger can't reproduce this body");
    }
    _assertLedgerReproducible(body.serialize(forJson: false));

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
      fee: body.fee.toBigInt(),
      ttl: body.ttl?.toBigInt(),
      certificates: parsedCertificates,
      withdrawals: parsedWithdrawals,
      // The body's key 7 is what gets signed, not whatever aux data happens to be attached
      auxiliaryData: body.metadataHash == null
          ? null
          : ParsedTxAuxiliaryData.arbitraryHash(hashHex: body.metadataHash!.hexEncode()),
      validityIntervalStart: body.validityStartInterval?.toBigInt(),
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
      totalCollateral: body.totalCollateral?.toBigInt(),
      votingProcedures: parsedVoterVotes,
      donation: body.donation?.toBigInt(),
      treasury: body.currentTreasuryValue?.toBigInt(),
      referenceInputs: body.referenceInputs?.toParsedInputs(inputUtxoToSigningPath: inputUtxoToSigningPath),
    );
    final signingMode = determineSigningMode(parsedTransaction);

    /**
     * If true, serialize transactions with 258 tags for all sets (optional since Conway).
     * If false or not given, do not use the tags.
     */
    final options = ParsedTransactionOptions(
      tagCborSets: setTags.single,
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

/// Throws [NotSupportedError] on the first item in [value] that Ledger would re-encode differently:
/// indefinite-length lists, maps, byte strings and text strings, and maps whose integer keys are not ascending
/// (post-Alonzo outputs). Inline datums and reference scripts are opaque byte strings here, matching what the
/// device receives.
void _assertLedgerReproducible(CborValue value) {
  final (lengthType, kind) = switch (value) {
    CborList() => (value.type, "list"),
    CborMap() => (value.type, "map"),
    CborBytes() => (value.type, "byte string"),
    CborString() => (value.type, "text string"),
    _ => (CborLengthType.definite, ""),
  };
  if (lengthType == CborLengthType.indefinite) {
    throw NotSupportedError("Indefinite-length CBOR $kind in the transaction body; Ledger can't reproduce this body");
  }

  if (value is CborMap) {
    final keys = value.keys.toList();
    if (keys.every((key) => key is CborInt)) {
      final intKeys = keys.cast<CborInt>().map((key) => key.toBigInt()).toList();
      for (var i = 1; i < intKeys.length; i++) {
        if (intKeys[i] <= intKeys[i - 1]) {
          throw NotSupportedError("CBOR map keys are not in ascending order; Ledger can't reproduce this body");
        }
      }
    }
    value.forEach((key, item) {
      _assertLedgerReproducible(key);
      _assertLedgerReproducible(item);
    });
  } else if (value is CborList) {
    value.forEach(_assertLedgerReproducible);
  }
}
