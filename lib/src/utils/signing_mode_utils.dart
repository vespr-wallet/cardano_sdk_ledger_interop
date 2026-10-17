import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../errors/errors.dart";

/// Picks the signing mode the device will accept, mirroring the per-mode rules of ledgerjs
/// (`parseSignTransactionRequest`): ordinary when every credential the device witnesses is a key path, multisig when
/// they are all script hashes, plutus otherwise. Pool registration has no mode this package can produce.
TransactionSigningModes determineSigningMode(ParsedTransaction tx) {
  final certificates = tx.certificates ?? const <ParsedCertificate>[];
  if (certificates.any((cert) => cert is StakePoolRegistration)) {
    throw InvalidTransactionError("Pool registration certificates have no supported Ledger signing mode");
  }

  final credentials = [
    ...certificates.map(_authorizingCredential).nonNulls,
    ...?tx.withdrawals?.map((withdrawal) => withdrawal.stakeCredential),
  ];
  final voterVotes = tx.votingProcedures ?? const <ParsedVoterVotes>[];
  final hasCollateralOrReferenceInputs = (tx.collateralInputs?.isNotEmpty ?? false) ||
      tx.collateralOutput != null ||
      tx.totalCollateral != null ||
      (tx.referenceInputs?.isNotEmpty ?? false);
  // ponytail: the device allows required signers in every mode; keeping them out of ordinary and multisig preserves
  // the previous behaviour (such transactions sign in plutus mode).
  final hasRequiredSigners = tx.requiredSigners?.isNotEmpty ?? false;

  if (hasCollateralOrReferenceInputs || hasRequiredSigners) return TransactionSigningModes.plutusTransaction;

  if (credentials.every((credential) => credential is CredentialKeyPath) && voterVotes.every(_isKeyPathVoter)) {
    return TransactionSigningModes.ordinaryTransaction;
  }

  // Inputs with a path would need 1852' witnesses, which multisig mode rejects (it signs with 1854' paths only).
  if (tx.inputs.every((input) => input.path == null) &&
      tx.outputs.every((output) => output.destination is ThirdParty) &&
      certificates.every((cert) => cert is! StakePoolRetirement) &&
      credentials.every((credential) => credential is CredentialScriptHash) &&
      voterVotes.every(_isScriptHashVoter)) {
    return TransactionSigningModes.multisigTransaction;
  }

  return TransactionSigningModes.plutusTransaction;
}

ParsedCredential? _authorizingCredential(ParsedCertificate cert) => switch (cert) {
      StakeRegistration() => cert.stakeCredential,
      StakeRegistrationConway() => cert.stakeCredential,
      StakeDeregistration() => cert.stakeCredential,
      StakeDeregistrationConway() => cert.stakeCredential,
      StakeDelegation() => cert.stakeCredential,
      VoteDelegation() => cert.stakeCredential,
      StakePoolAndDRepDelegation() => cert.stakeCredential,
      AccountRegistrationDelegationToStakePool() => cert.stakeCredential,
      AccountRegistrationDelegationToDRep() => cert.stakeCredential,
      AccountRegistrationDelegationToStakePoolAndDRep() => cert.stakeCredential,
      AuthorizeCommitteeHot() => cert.coldCredential,
      ResignCommitteeCold() => cert.coldCredential,
      DRepRegistration() => cert.dRepCredential,
      DRepDeregistration() => cert.dRepCredential,
      DRepUpdate() => cert.dRepCredential,
      // Pool certificates are witnessed by the pool cold key, not by a credential in the certificate.
      StakePoolRegistration() => null,
      StakePoolRetirement() => null,
    };

bool _isKeyPathVoter(ParsedVoterVotes voterVotes) => switch (voterVotes.voter) {
      CommitteeKeyPath() || DrepKeyPath() || StakePoolKeyPath() => true,
      CommitteeKeyHash() || CommitteeScriptHash() || DrepKeyHash() || DrepScriptHash() || StakePoolKeyHash() => false,
    };

bool _isScriptHashVoter(ParsedVoterVotes voterVotes) => switch (voterVotes.voter) {
      CommitteeScriptHash() || DrepScriptHash() => true,
      CommitteeKeyPath() ||
      DrepKeyPath() ||
      StakePoolKeyPath() ||
      CommitteeKeyHash() ||
      DrepKeyHash() ||
      StakePoolKeyHash() =>
        false,
    };
