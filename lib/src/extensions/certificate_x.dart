import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../errors/errors.dart";
import "anchor_x.dart";
import "credential_x.dart";
import "drep_x.dart";

extension CertificateX on Certificate {
  ParsedCertificate toParsedCertificate({
    required int accountIndex,
    required String stakeCredsHex,
    required String dRepKeyHashHex,
    required String coldCredentialKeyHashHex,
    required String hotCredentialKeyHashHex,
  }) {
    final cert = this;
    return switch (cert) {
      Certificate_StakeRegistrationLegacy() => ParsedCertificate.stakeRegistration(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
        ),
      Certificate_StakeDeRegistrationLegacy() => ParsedCertificate.stakeDeregistration(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
        ),
      Certificate_StakeDelegation() => ParsedCertificate.stakeDelegation(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          poolKeyHashHex: cert.stakePoolId.hexPoolId,
        ),
      Certificate_StakeRegistration() => ParsedCertificate.stakeRegistrationConway(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
        ),
      Certificate_StakeDeRegistration() => ParsedCertificate.stakeDeregistrationConway(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
        ),
      // Pool certificates need the pool cold key (1853') or owner/operator mappings this package doesn't derive.
      // The old mapping dropped relays and sent the stake path as the pool key, so the device would have signed a
      // different certificate; failing here keeps the device out of it.
      Certificate_PoolRegistration() =>
        throw NotSupportedError("Pool registration certificates are not supported for Ledger signing"),
      Certificate_PoolRetirement() =>
        throw NotSupportedError("Pool retirement certificates are not supported for Ledger signing"),
      Certificate_VoteDelegation() => ParsedCertificate.voteDelegation(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          dRep: cert.dRep.toParsedDRep(
            walletDrepKeyHashHex: dRepKeyHashHex,
            account: accountIndex,
          ),
        ),
      Certificate_StakeVoteDelegation() => ParsedCertificate.stakePoolAndDRepDelegation(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          poolKeyHashHex: cert.stakePoolId.hexPoolId,
          dRep: cert.dRep.toParsedDRep(
            walletDrepKeyHashHex: dRepKeyHashHex,
            account: accountIndex,
          ),
        ),
      Certificate_StakeRegistrationDelegation() => ParsedCertificate.accountRegistrationDelegationToStakePool(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
          poolKeyHashHex: cert.stakePoolId.hexPoolId,
        ),
      Certificate_VoteRegistrationDelegation() => ParsedCertificate.accountRegistrationDelegationToDRep(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
          dRep: cert.dRep.toParsedDRep(
            walletDrepKeyHashHex: dRepKeyHashHex,
            account: accountIndex,
          ),
        ),
      Certificate_StakeVoteRegistrationDelegation() =>
        ParsedCertificate.accountRegistrationDelegationToStakePoolAndDRep(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
          poolKeyHashHex: cert.stakePoolId.hexPoolId,
          dRep: cert.dRep.toParsedDRep(
            walletDrepKeyHashHex: dRepKeyHashHex,
            account: accountIndex,
          ),
        ),
      Certificate_AuthorizeCommitteeHot() => ParsedCertificate.authorizeCommitteeHot(
          coldCredential: cert.committeeColdCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.constitutionalCommitteeCold,
            walletCredsHex: coldCredentialKeyHashHex,
          ),
          hotCredential: cert.committeeHotCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.constitutionalCommitteeHot,
            walletCredsHex: hotCredentialKeyHashHex,
          )),
      Certificate_ResignCommitteeCold() => ParsedCertificate.resignCommitteeCold(
          coldCredential: cert.committeeColdCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.constitutionalCommitteeCold,
            walletCredsHex: coldCredentialKeyHashHex,
          ),
          anchor: cert.anchor?.toParsedAnchor(),
        ),
      Certificate_RegisterDRep() => ParsedCertificate.dRepRegistration(
          dRepCredential: cert.dRepCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.drepCredential,
            walletCredsHex: dRepKeyHashHex,
          ),
          deposit: cert.coin.toBigInt(),
          anchor: cert.anchor?.toParsedAnchor(),
        ),
      Certificate_UnregisterDRep() => ParsedCertificate.dRepDeregistration(
          dRepCredential: cert.dRepCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.drepCredential,
            walletCredsHex: dRepKeyHashHex,
          ),
          deposit: cert.coin.toBigInt(),
        ),
      Certificate_UpdateDRep() => ParsedCertificate.dRepUpdate(
          dRepCredential: cert.dRepCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.drepCredential,
            walletCredsHex: dRepKeyHashHex,
          ),
          anchor: cert.anchor?.toParsedAnchor(),
        ),
    };
  }
}
