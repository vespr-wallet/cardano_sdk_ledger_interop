import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
// RationalNumber is not exported by cardano_dart_types 3.1.2 even though Certificate.poolRegistration requires it.
import "package:cardano_dart_types/src/cardano/shared/rational_number.dart";
import "package:cardano_sdk_ledger_interop/cardano_sdk_ledger_interop.dart";
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

  group("anchors", () {
    const anchorUrl = "https://example.com/drep.jsonld";
    final anchor = Anchor(anchorUrl: anchorUrl, anchorDataHash: Uint8List.fromList(List.filled(32, 0x44)));
    final parsedAnchor = ParsedAnchor(url: anchorUrl, hashHex: "44" * 32);
    final dRepCredential = Credential(CredType.ADDR_KEY_HASH, dRepKeyHashHex.hexDecode());
    const coldKeyHashHex = "55555555555555555555555555555555555555555555555555555555";
    final coldCredential = Credential(CredType.ADDR_KEY_HASH, coldKeyHashHex.hexDecode());

    test("DRep registration keeps its anchor", () {
      expect(
        mapCertificate(Certificate.registerDRep(dRepCredential: dRepCredential, coin: deposit, anchor: anchor)),
        ParsedCertificate.dRepRegistration(
          dRepCredential: parsedDRep.toCredential(),
          deposit: deposit.toBigInt(),
          anchor: parsedAnchor,
        ),
      );
    });

    test("committee cold resignation keeps its anchor", () {
      expect(
        mapCertificate(Certificate.resignCommitteeCold(committeeColdCredential: coldCredential, anchor: anchor)),
        ParsedCertificate.resignCommitteeCold(
          coldCredential: ParsedCredential.keyHash(keyHashHex: coldKeyHashHex),
          anchor: parsedAnchor,
        ),
      );
    });

    test("DRep registration without anchor maps to null", () {
      expect(
        mapCertificate(Certificate.registerDRep(dRepCredential: dRepCredential, coin: deposit, anchor: null)),
        ParsedCertificate.dRepRegistration(dRepCredential: parsedDRep.toCredential(), deposit: deposit.toBigInt()),
      );
    });
  });

  group("pool certificates", () {
    test("pool retirement is rejected", () {
      final certificate = Certificate.poolRetirement(operator: stakePoolId, epoch: BigInt.from(500).toCborInt());
      expect(() => mapCertificate(certificate), throwsA(isA<NotSupportedError>()));
    });

    test("pool registration is rejected", () {
      final certificate = Certificate.poolRegistration(
        operator: stakePoolId,
        vrfKeyHash: Uint8List(32),
        pledge: deposit,
        cost: deposit,
        margin: RationalNumber(numerator: BigInt.one, denominator: BigInt.from(100)),
        rewardAccount: Uint8List.fromList([0xe1, ...stakeCredentialsHex.hexDecode()]),
        poolOwners: [stakeCredentialsHex.hexDecode()],
        relays: CborList([]),
        poolMetadata: null,
      );
      expect(() => mapCertificate(certificate), throwsA(isA<NotSupportedError>()));
    });
  });
}

extension on ParsedDRep {
  /// The DRep key path credential matching this parsed DRep.
  ParsedCredential toCredential() => ParsedCredential.keyPath(path: (this as DRepKeyPath).path);
}
