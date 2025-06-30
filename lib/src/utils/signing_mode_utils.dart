import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../errors/errors.dart";

TransactionSigningModes determineSigningMode({
  required List<ParsedCertificate>? parsedCertificates,
  required List<ParsedInput> inputs,
  required List<ParsedOutput> outputs,
  required List<ParsedInput>? collateralInputs,
  required RequiredSigners? requiredSigners,
  required List<Withdraw>? withdrawals,
  required List<MultiAsset>? mint,
  required List<ParsedVoterVotes>? votingProcedures,
  required Uint8List? scriptDataHash,
  required String stakeCredentialsHex,
}) {
  final certsCreds = parsedCertificates
      ?.map((parsedCert) => switch (parsedCert) {
            StakeRegistration() => parsedCert.stakeCredential,
            StakeRegistrationConway() => parsedCert.stakeCredential,
            StakeDeregistration() => parsedCert.stakeCredential,
            StakeDeregistrationConway() => parsedCert.stakeCredential,
            StakeDelegation() => parsedCert.stakeCredential,
            VoteDelegation() => parsedCert.stakeCredential,
            AuthorizeCommitteeHot() => parsedCert.coldCredential,
            ResignCommitteeCold() => parsedCert.coldCredential,
            DRepRegistration() => parsedCert.dRepCredential,
            DRepDeregistration() => parsedCert.dRepCredential,
            DRepUpdate() => parsedCert.dRepCredential,
            StakePoolRegistration() => false,
            StakePoolRetirement() => false,
          })
      .toList(growable: false);

  final allInputsArePath = inputs.every((input) => input.path != null);
  final hasPoolRegistrationCert = parsedCertificates?.any((parsedCert) => parsedCert is StakePoolRegistration) ?? false;
  final allCertsArePath =
      // ignore: avoid_bool_literals_in_conditional_expressions
      hasPoolRegistrationCert ? false : certsCreds?.every((cred) => cred is CredentialKeyPath) ?? true;

  final hasCollateralInputs = collateralInputs?.isNotEmpty ?? false;
  final hasRequiredSigners = requiredSigners?.signersBytes.isNotEmpty ?? false;

  final allVotingProceduresArePath = votingProcedures?.every((v) => switch (v.voter) {
            CommitteeKeyPath() => true,
            DrepKeyPath() => true,
            StakePoolKeyPath() => true,
            // if it's hash, reject it
            CommitteeKeyHash() => false,
            CommitteeScriptHash() => false,
            DrepKeyHash() => false,
            DrepScriptHash() => false,
            StakePoolKeyHash() => false,
          }) ??
      true;

  if (allInputsArePath &&
      allCertsArePath &&
      // allVotingProceduresArePath has been added despite not being mentioned in the JS library
      // because when there's hash voting procedures (in the TS library), the tests are always using
      // plutus transaciton type
      allVotingProceduresArePath &&
      !hasPoolRegistrationCert &&
      !hasCollateralInputs &&
      !hasRequiredSigners) {
    // Checks omitted:
    //  * - *must* contain only 1852 and 1855 paths
    //  * - *must* contain 1855 witness requests only when transaction contains token minting/burning
    return TransactionSigningModes.ordinaryTransaction;
  }

  final allInputsAreThirdParty = inputs.every((input) => input.path == null);
  final allOutputsAreThirdParty = outputs.every((output) => output.destination is ThirdParty);
  final someCertsAreScriptHash = certsCreds?.any((cred) => cred is CredentialScriptHash) ?? false;

  if (allInputsAreThirdParty &&
      allOutputsAreThirdParty &&
      !hasPoolRegistrationCert &&
      someCertsAreScriptHash &&
      !hasCollateralInputs &&
      !hasRequiredSigners) {
    // Checks omitted:
    //  * - *must* contain only 1854 and 1855 witness requests
    //  * - *must* contain 1855 witness requests only when transaction contains token minting/burning
    return TransactionSigningModes.multisigTransaction;
  }

  final noOutputsHaveDatum = outputs.every((output) => output.outputDatum == null);
  final hasSinglePoolRegCertAsOwner = () {
    if (parsedCertificates == null) return false;
    if (parsedCertificates.length != 1) return false;

    final cert = parsedCertificates.first;
    if (cert is! StakePoolRegistration) return false;
    if (cert.pool.owners.length != 1) return false;

    final owner = cert.pool.owners.first;
    return switch (owner) {
      DeviceOwnedPoolOwner() => true,
      ThirdPartyPoolOwner() => false,
    };
  }();
  final hasWithdrawals = withdrawals?.isNotEmpty ?? false;
  final hasMint = mint?.isNotEmpty ?? false;
  final hasScriptDataHash = scriptDataHash != null;

  if (allInputsAreThirdParty &&
      allOutputsAreThirdParty &&
      noOutputsHaveDatum &&
      hasSinglePoolRegCertAsOwner &&
      !hasWithdrawals &&
      !hasMint &&
      !hasScriptDataHash &&
      !hasCollateralInputs &&
      !hasRequiredSigners) {
    // Checks omitted:
    //  * - *must* contain only staking witness requests
    return TransactionSigningModes.poolRegistrationAsOwner;
  }

  final hasSinglePoolRegCertAsOperator = () {
    if (parsedCertificates == null) return false;
    if (parsedCertificates.length != 1) return false;

    final cert = parsedCertificates.first;
    if (cert is! StakePoolRegistration) return false;
    if (cert.pool.owners.length != 1) return false;

    final owner = cert.pool.owners.first;
    if (owner is! ThirdPartyPoolOwner) return false;

    return switch (cert.pool.poolKey) {
      DeviceOwnedPoolKey() => true,
      ThirdPartyPoolKey() => false,
    };
  }();

  if (allInputsArePath &&
      noOutputsHaveDatum &&
      hasSinglePoolRegCertAsOperator &&
      !hasWithdrawals &&
      !hasMint &&
      !hasScriptDataHash &&
      !hasCollateralInputs &&
      !hasRequiredSigners) {
    return TransactionSigningModes.poolRegistrationAsOperator;
  }

  if (hasPoolRegistrationCert) {
    throw InvalidTransactionError(
      "Transaction contains a pool registration certificate but does not meet any of the known signing modes",
    );
  }
  return TransactionSigningModes.plutusTransaction;
}
