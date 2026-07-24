import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_sdk_ledger_interop/src/extensions/certificate_x.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
import "package:test/test.dart";

void main() {
  const accountIndex = 3;
  const stakeCredentialsHex = "11111111111111111111111111111111111111111111111111111111";
  const dRepKeyHashHex = "22222222222222222222222222222222222222222222222222222222";
  const poolKeyHashHex = "33333333333333333333333333333333333333333333333333333333";
  final stakeCredential = Credential(CredType.ADDR_KEY_HASH, stakeCredentialsHex.hexDecode());
  final parsedStakeCredential = ParsedCredential.keyPath(
    path: LedgerSigningPath.shelley(
      account: accountIndex,
      address: 0,
      role: ShelleyAddressRole.stake,
    ),
  );
  final dRep = Drep.addrKeyHash(
    hash: dRepKeyHashHex,
    lengthType: CborLengthType.definite,
  );
  final parsedDRep = ParsedDRep.keyPath(
    path: LedgerSigningPath.shelley(
      account: accountIndex,
      address: 0,
      role: ShelleyAddressRole.drepCredential,
    ),
  );
  final stakePoolId = StakePoolId.fromHexPoolId(poolKeyHashHex);
  final deposit = BigInt.from(2000000).toCborInt();

  ParsedCertificate mapCertificate(Certificate certificate) => certificate.toParsedCertificate(
        accountIndex: accountIndex,
        stakeCredsHex: stakeCredentialsHex,
        dRepKeyHashHex: dRepKeyHashHex,
        coldCredentialKeyHashHex: "",
        hotCredentialKeyHashHex: "",
      );

  test("maps Conway stake deregistration", () {
    final certificate = Certificate.stakeDeRegistration(
      stakeCredential: stakeCredential,
      coin: deposit,
    );

    expect(
      mapCertificate(certificate),
      ParsedCertificate.stakeDeregistrationConway(
        stakeCredential: parsedStakeCredential,
        deposit: deposit.toBigInt(),
      ),
    );
  });

  test("maps Ledger v8 combined Conway delegation certificates", () {
    final cases = <({Certificate certificate, ParsedCertificate expected})>[
      (
        certificate: Certificate.stakeVoteDelegation(
          stakeCredential: stakeCredential,
          stakePoolId: stakePoolId,
          dRep: dRep,
        ),
        expected: ParsedCertificate.stakePoolAndDRepDelegation(
          stakeCredential: parsedStakeCredential,
          poolKeyHashHex: poolKeyHashHex,
          dRep: parsedDRep,
        ),
      ),
      (
        certificate: Certificate.stakeRegistrationDelegation(
          stakeCredential: stakeCredential,
          stakePoolId: stakePoolId,
          coin: deposit,
        ),
        expected: ParsedCertificate.accountRegistrationDelegationToStakePool(
          stakeCredential: parsedStakeCredential,
          deposit: deposit.toBigInt(),
          poolKeyHashHex: poolKeyHashHex,
        ),
      ),
      (
        certificate: Certificate.voteRegistrationDelegation(
          stakeCredential: stakeCredential,
          dRep: dRep,
          coin: deposit,
        ),
        expected: ParsedCertificate.accountRegistrationDelegationToDRep(
          stakeCredential: parsedStakeCredential,
          deposit: deposit.toBigInt(),
          dRep: parsedDRep,
        ),
      ),
      (
        certificate: Certificate.stakeVoteRegistrationDelegation(
          stakeCredential: stakeCredential,
          stakePoolId: stakePoolId,
          dRep: dRep,
          coin: deposit,
        ),
        expected: ParsedCertificate.accountRegistrationDelegationToStakePoolAndDRep(
          stakeCredential: parsedStakeCredential,
          deposit: deposit.toBigInt(),
          poolKeyHashHex: poolKeyHashHex,
          dRep: parsedDRep,
        ),
      ),
    ];

    for (final testCase in cases) {
      expect(mapCertificate(testCase.certificate), testCase.expected);
    }
  });
}
