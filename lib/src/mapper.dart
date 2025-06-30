import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "extensions/auxiliary_data_x.dart";
import "extensions/certificate_x.dart";
import "extensions/multi_asset_x.dart";
import "extensions/required_signer_x.dart";
import "extensions/tx_inputs_x.dart";
import "extensions/tx_output_x.dart";
import "extensions/voting_procedures_x.dart";
import "extensions/withdrawal_x.dart";
import "models/signature_request_data.dart";
import "types.dart";
import "utils/signing_mode_utils.dart";

extension ShelleyTransactionMapper on CardanoTransaction {
  Future<SignatureRequestData> toLedgerSigningRequest({
    required NetworkId networkId,
    required String xPubBech32,
    required int accountIndex,
    // Ideally this maxDeriveAddressCount should be based on the payment creds observed on chain
    required int maxDeriveAddressCount,
    required Map<UtxoAndIndex, Bech32OrBase58CardanoAddress> inputUtxoToAddress,
  }) async {
    final CardanoPubAccount cardanoPubAcc = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);
    final String stakeCredentialsHex = await cardanoPubAcc.stakeCredentialsHex();

    final [paymentCreds, changeCreds] = await Future.wait([
      cardanoPubAcc.deriveCredentialsHex(
        startIndex: 0,
        endIndex: maxDeriveAddressCount,
        role: Bip32KeyRole.payment,
      ),
      cardanoPubAcc.deriveCredentialsHex(
        startIndex: 0,
        endIndex: maxDeriveAddressCount,
        role: Bip32KeyRole.change,
      ),
    ]);

    final Map<CredentialsHex, LedgerSigningPath> paymentCredsToSigningPath = Map.fromEntries(
      paymentCreds.indexed.map(
        (indexAndCred) => MapEntry(
          indexAndCred.$2,
          LedgerSigningPath.shelley(
            account: accountIndex,
            address: indexAndCred.$1,
            role: ShelleyAddressRole.payment,
          ),
        ),
      ),
    );

    final Map<CredentialsHex, LedgerSigningPath> changeCredsToSigningPath = Map.fromEntries(
      changeCreds.indexed.map(
        (indexAndCred) => MapEntry(
          indexAndCred.$2,
          LedgerSigningPath.shelley(
            account: accountIndex,
            address: indexAndCred.$1,
            role: ShelleyAddressRole.change,
          ),
        ),
      ),
    );

    // Should contain creds of all derivations
    final Map<CredentialsHex, LedgerSigningPath> derivedCredsToSigningPath = {
      ...paymentCredsToSigningPath,
      ...changeCredsToSigningPath,
      // Credentials in HEX
      stakeCredentialsHex: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.stake,
      ),
      cardanoPubAcc.dRepDerivation.value.credentialsHex: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.drepCredential,
      ),
      cardanoPubAcc.constitutionalCommitteeColdDerivation.value.hexCredential: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeCold,
      ),
      cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCredential: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeHot,
      ),
      // Raw Keys in HEX || NOT SURE IF WE ACTUALLY NEED THOSE HERE
      // -- I think on-chain we'll only see the hex credentials, not the vkey
      cardanoPubAcc.stakeKey.rawKey.hexEncode(): LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.stake,
      ),
      cardanoPubAcc.dRepDerivation.value.dRepKeyHex: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.drepCredential,
      ),
      cardanoPubAcc.constitutionalCommitteeColdDerivation.value.hexCCKey: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeCold,
      ),
      cardanoPubAcc.constitutionalCommitteeHotDerivation.value.hexCCKey: LedgerSigningPath.shelley(
        account: accountIndex,
        address: 0,
        role: ShelleyAddressRole.constitutionalCommitteeHot,
      ),
    };

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

    final parsedCertificates = body.certs
        ?.map(
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

extension _Uint8ListX on Uint8List {
  ScriptDataHash toScriptDataHash() => ScriptDataHash(hexString: hexEncode());
}
