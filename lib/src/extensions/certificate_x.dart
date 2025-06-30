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
      Certificate_StakeDeRegistration() => ParsedCertificate.stakeRegistrationConway(
          stakeCredential: cert.stakeCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.stake,
            walletCredsHex: stakeCredsHex,
          ),
          deposit: cert.coin.toBigInt(),
        ),
      Certificate_PoolRegistration() => ParsedCertificate.stakePoolRegistration(
          pool: ParsedPoolParams(
            cost: cert.cost.toBigInt(),
            pledge: cert.pledge.toBigInt(),
            margin: ParsedMargin(denominator: cert.margin.denominator, numerator: cert.margin.numerator),
            metadata: cert.poolMetadata == null
                ? null
                : ParsedPoolMetadata(
                    url: cert.poolMetadata!.metadataUrl,
                    hashHex: cert.poolMetadata!.metadataHashHex.value,
                  ),
            rewardAccount: cert.rewardAccount.hexEncode() == stakeCredsHex
                ? ParsedPoolRewardAccount.deviceOwned(
                    path: LedgerSigningPath.shelley(account: accountIndex, address: 0, role: ShelleyAddressRole.stake),
                  )
                : ParsedPoolRewardAccount.thirdParty(rewardAccountHex: cert.rewardAccount.hexEncode()),
            vrfHashHex: cert.vrfKeyHash.hexEncode(),
            owners: cert.poolOwners
                .map(
                  // TODOincorrect mapping here
                  (owner) => ParsedPoolOwner.thirdParty(hashHex: owner.hexEncode()),
                )
                .toList(),
            // TODOincorrect mapping here
            poolKey: ParsedPoolKey.thirdParty(hashHex: cert.operator.poolKeyHash.hexEncode()),
            // TODOincorrect mapping here
            relays: [],
          ),
        ),
      Certificate_PoolRetirement() => ParsedCertificate.stakePoolRetirement(
          // TODOlikely incorrect mapping here
          path: LedgerSigningPath.shelley(account: accountIndex, address: 0, role: ShelleyAddressRole.stake),
          retirementEpoch: cert.epoch.toBigInt(),
        ),
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
      Certificate_StakeVoteDelegation() => throw NotSupportedError(
          "StakeVoteDelegation certificate is not supported",
        ),
      Certificate_StakeRegistrationDelegation() => throw NotSupportedError(
          "StakeRegistrationDelegation certificate is not supported",
        ),
      Certificate_VoteRegistrationDelegation() => throw NotSupportedError(
          "VoteRegistrationDelegation certificate is not supported",
        ),
      Certificate_StakeVoteRegistrationDelegation() => throw NotSupportedError(
          "StakeVoteRegistrationDelegation certificate is not supported",
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
        ),
      Certificate_RegisterDRep() => ParsedCertificate.dRepRegistration(
          dRepCredential: cert.dRepCredential.toParsedCredential(
            accountIndex: accountIndex,
            addressIndex: 0,
            role: ShelleyAddressRole.drepCredential,
            walletCredsHex: dRepKeyHashHex,
          ),
          deposit: cert.coin.toBigInt(),
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
