import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_sdk_ledger_interop/src/impl/message_signing_ledger_mapper.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
// ignore: depend_on_referenced_packages
import "package:pinenacl/encoding.dart";
import "package:test/test.dart";

enum _AddEncoding { bech32, hex, hex_cred }

void main() async {
  const xPubBech32 =
      "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0";
  final ledgerPubAccount = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);

  group("MessageSigningLedgerMapper", () {
    late MessageSigningLedgerMapper mapper;

    setUpAll(() {
      mapper = const MessageSigningLedgerMapper();
    });

    group("Constants", () {
      test("cip08SignHashThreshold should be 100", () {
        expect(cip08SignHashThreshold, equals(100));
      });
    });

    group("toDataSignature", () {
      test("hashed payload returns correctly", () async {
        const payloadHex = "546869732069732061207465737420706179616f6164"; // "This is a test payaoad"

        const data = SignedMessageData(
          signatureHex:
              "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
          addressFieldHex: "fedcba0987654321fedcba0987654321fedcba09",
          signingPublicKeyHex: "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fe",
          signatureType: DataSignatureType.paylod,
        );

        final result = await mapper.toDataSignature(
          data: data,
          payloadHex: payloadHex,
        );

        const expected = DataSignature(
          coseKeyHex: "a4010103272006215821fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fe",
          coseSignHex:
              "845820a20127676164647265737354fedcba0987654321fedcba0987654321fedcba09a166686173686564f456546869732069732061207465737420706179616f61645848fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
        );

        expect(result, equals(expected));
      });

      test("non-hashed payload returns correctly", () async {
        const payloadHex = "546869732069732061207465737420706179616f6164"; // "This is a test payaoad"

        const hashedData = SignedMessageData(
          signatureHex:
              "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
          addressFieldHex: "fedcba0987654321fedcba0987654321fedcba09",
          signingPublicKeyHex: "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fe",
          signatureType: DataSignatureType.payload_black2b_hash_28_bytes,
        );

        final hashedResult = await mapper.toDataSignature(
          data: hashedData,
          payloadHex: payloadHex,
        );

        const expected = DataSignature(
          coseKeyHex: "a4010103272006215821fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fe",
          coseSignHex:
              "845820a20127676164647265737354fedcba0987654321fedcba0987654321fedcba09a166686173686564f5581c6a5e4b5d7b185c6a166f62141640b0532277787607f1c09163798eb45848fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
        );

        expect(hashedResult, equals(expected));
      });
    });

    group("toParsedMessageData", () {
      group("Success Cases", () {
        final testCases = [
          (
            description: "short payload",
            payloadHex: "546869732069732061207465737420706179616f6164", // "This is a test payaoad"
            expectHashPayload: false,
          ),
          (
            description: "long payload",
            payloadHex: "546869732069732061207465737420706179616f6164" * 10, // "This is a test payaoad" * 10
            expectHashPayload: true,
          ),
        ];

        for (final testCase in testCases) {
          final rawPayloadHex = testCase.payloadHex;
          final expectHashPayload = testCase.expectHashPayload;

          group(testCase.description, () {
            for (final encoding in _AddEncoding.values) {
              group("$encoding signer -", () {
                for (final addrIndex in [0, 4, 5]) {
                  test("base address - address index $addrIndex", () async {
                    final signer = switch (encoding) {
                      _AddEncoding.bech32 =>
                        (await ledgerPubAccount.paymentAddress(addrIndex, NetworkId.mainnet)).bech32Encoded,
                      _AddEncoding.hex =>
                        (await ledgerPubAccount.paymentAddress(addrIndex, NetworkId.mainnet)).hexEncoded,
                      _AddEncoding.hex_cred => null,
                    };
                    if (signer == null) {
                      // Not-applicable for this encoding
                    } else {
                      final data = await mapper.toParsedMessageData(
                        xPubBech32: xPubBech32,
                        accountIndex: 0,
                        deriveMaxAddressCount: 10,
                        messageHex: rawPayloadHex,
                        requestedSignerRaw: signer,
                      );

                      final expected = ParsedMessageData.address(
                        messageHex: rawPayloadHex,
                        signingPath:
                            LedgerSigningPath.shelley(account: 0, address: addrIndex, role: ShelleyAddressRole.payment),
                        hashPayload: expectHashPayload,
                        address: ParsedAddressParams.shelley(
                          shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                            spendingDataSource: SpendingDataSourcePath(
                              path: LedgerSigningPath.shelley(
                                  account: 0, address: addrIndex, role: ShelleyAddressRole.payment),
                            ),
                            stakingDataSource: StakingDataSourceKey(
                              data: StakingDataSourceKeyData.path(
                                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                              ),
                            ),
                          ),
                        ),
                      );

                      expect(data, equals(expected));
                    }
                  });

                  test("enterprise address - address index $addrIndex", () async {
                    final signer = switch (encoding) {
                      _AddEncoding.bech32 => CardanoAddress.fromHexPaymentCredentials(
                          paymentCredentials:
                              (await ledgerPubAccount.paymentAddress(addrIndex, NetworkId.mainnet)).credentials,
                          networkId: NetworkId.mainnet,
                        ).bech32Encoded,
                      _AddEncoding.hex => CardanoAddress.fromHexPaymentCredentials(
                          paymentCredentials:
                              (await ledgerPubAccount.paymentAddress(addrIndex, NetworkId.mainnet)).credentials,
                          networkId: NetworkId.mainnet,
                        ).hexEncoded,
                      _AddEncoding.hex_cred => null,
                    };
                    if (signer == null) {
                      // Not-applicable for this encoding
                    } else {
                      final data = await mapper.toParsedMessageData(
                        xPubBech32: xPubBech32,
                        accountIndex: 0,
                        deriveMaxAddressCount: 10,
                        messageHex: rawPayloadHex,
                        requestedSignerRaw: signer,
                      );

                      final expected = ParsedMessageData.address(
                        messageHex: rawPayloadHex,
                        signingPath:
                            LedgerSigningPath.shelley(account: 0, address: addrIndex, role: ShelleyAddressRole.payment),
                        hashPayload: expectHashPayload,
                        address: ParsedAddressParams.shelley(
                          shelleyAddressParams: ShelleyAddressParamsData.enterpriseKey(
                            spendingDataSource: SpendingDataSourcePath(
                              path: LedgerSigningPath.shelley(
                                  account: 0, address: addrIndex, role: ShelleyAddressRole.payment),
                            ),
                          ),
                        ),
                      );

                      expect(data, equals(expected));
                    }
                  });
                }

                test("staking address", () async {
                  final data = await mapper.toParsedMessageData(
                    xPubBech32: xPubBech32,
                    accountIndex: 0,
                    deriveMaxAddressCount: 10,
                    messageHex: rawPayloadHex,
                    requestedSignerRaw: switch (encoding) {
                      _AddEncoding.bech32 => (await ledgerPubAccount.stakeAddress(NetworkId.mainnet)),
                      _AddEncoding.hex_cred => (await ledgerPubAccount.stakeAddress(NetworkId.mainnet)).bech32ToHex(),
                      _AddEncoding.hex => (await ledgerPubAccount.stakeCredentialsHex()),
                    },
                  );

                  final expected = ParsedMessageData.address(
                    messageHex: rawPayloadHex,
                    signingPath: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                    hashPayload: expectHashPayload,
                    address: ParsedAddressParams.shelley(
                      shelleyAddressParams: ShelleyAddressParamsData.rewardKey(
                        stakingDataSource: StakingDataSourceKey(
                          data: StakingDataSourceKeyData.path(
                            path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                          ),
                        ),
                      ),
                    ),
                  );

                  expect(data, equals(expected));
                });

                test("drep CIP 129", () async {
                  final data = await mapper.toParsedMessageData(
                    xPubBech32: xPubBech32,
                    accountIndex: 0,
                    deriveMaxAddressCount: 10,
                    messageHex: rawPayloadHex,
                    requestedSignerRaw: switch (encoding) {
                      _AddEncoding.bech32 => ledgerPubAccount.dRepDerivation.value.dRepIdNewBech32,
                      _AddEncoding.hex_cred => ledgerPubAccount.dRepDerivation.value.dRepIdNewHex,
                      _AddEncoding.hex => ledgerPubAccount.dRepDerivation.value.credentialsHex,
                    },
                  );

                  final expected = ParsedMessageData.keyHash(
                    messageHex: rawPayloadHex,
                    signingPath:
                        LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.drepCredential),
                    hashPayload: expectHashPayload,
                  );

                  expect(data, equals(expected));
                });

                test("drep CIP 105 legacy", () async {
                  final data = await mapper.toParsedMessageData(
                    xPubBech32: xPubBech32,
                    accountIndex: 0,
                    deriveMaxAddressCount: 10,
                    messageHex: rawPayloadHex,
                    requestedSignerRaw: switch (encoding) {
                      _AddEncoding.bech32 => ledgerPubAccount.dRepDerivation.value.dRepIdLegacyBech32,
                      _AddEncoding.hex_cred => ledgerPubAccount.dRepDerivation.value.dRepIdLegacyHex,
                      _AddEncoding.hex => ledgerPubAccount.dRepDerivation.value.credentialsHex,
                    },
                  );

                  final expected = ParsedMessageData.keyHash(
                    messageHex: rawPayloadHex,
                    signingPath:
                        LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.drepCredential),
                    hashPayload: expectHashPayload,
                  );

                  expect(data, equals(expected));
                });
              });
            }
          });
        }

        test("should return correct data signature for valid input", () async {
          const payloadHex = "546869732069732061207465737420706179616f6164"; // "This is a test payaoad"

          final data = await mapper.toParsedMessageData(
            xPubBech32: xPubBech32,
            accountIndex: 0,
            deriveMaxAddressCount: 10,
            messageHex: payloadHex,
            requestedSignerRaw: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).bech32Encoded,
          );

          final expected = ParsedMessageData.address(
            messageHex: payloadHex,
            signingPath: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
            hashPayload: false,
            address: ParsedAddressParams.shelley(
              shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                spendingDataSource: SpendingDataSourcePath(
                  path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                ),
                stakingDataSource: StakingDataSourceKey(
                  data: StakingDataSourceKeyData.path(
                    path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                  ),
                ),
              ),
            ),
          );

          expect(data, equals(expected));
        });

        group("shouldHashPayload parameter", () {
          test("should force hashing when explicitly set to true for short message", () async {
            const shortPayloadHex = "48656c6c6f"; // "Hello" - only 10 hex chars

            final data = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: shortPayloadHex,
              requestedSignerRaw: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).bech32Encoded,
              shouldHashPayload: true,
            );

            expect(data.hashPayload, equals(true));
          });

          test("should not hash when explicitly set to false for long message", () async {
            final longPayloadHex = "546869732069732061207465737420706179616f6164" * 10; // > 100 hex chars

            final data = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: longPayloadHex,
              requestedSignerRaw: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).bech32Encoded,
              shouldHashPayload: false,
            );

            expect(data.hashPayload, equals(false));
          });

          test("should use default behavior when shouldHashPayload is null", () async {
            const shortPayloadHex = "48656c6c6f"; // "Hello" - only 10 hex chars
            final longPayloadHex = "546869732069732061207465737420706179616f6164" * 10; // > 100 hex chars

            final shortData = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: shortPayloadHex,
              requestedSignerRaw: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).bech32Encoded,
              shouldHashPayload: null,
            );

            final longData = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: longPayloadHex,
              requestedSignerRaw: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).bech32Encoded,
              shouldHashPayload: null,
            );

            expect(shortData.hashPayload, equals(false), reason: "Short message should not be hashed by default");
            expect(longData.hashPayload, equals(true), reason: "Long message should be hashed by default");
          });

          test("should work with different address types when shouldHashPayload is set", () async {
            const payloadHex = "546869732069732061207465737420706179616f6164";

            // Test with stake address
            final stakeData = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: payloadHex,
              requestedSignerRaw: await ledgerPubAccount.stakeAddress(NetworkId.mainnet),
              shouldHashPayload: true,
            );

            expect(stakeData.hashPayload, equals(true));

            // Test with enterprise address
            final enterpriseAddress = CardanoAddress.fromHexPaymentCredentials(
              paymentCredentials: (await ledgerPubAccount.paymentAddress(0, NetworkId.mainnet)).credentials,
              networkId: NetworkId.mainnet,
            );

            final enterpriseData = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: payloadHex,
              requestedSignerRaw: enterpriseAddress.bech32Encoded,
              shouldHashPayload: false,
            );

            expect(enterpriseData.hashPayload, equals(false));

            // Test with DRep
            final drepData = await mapper.toParsedMessageData(
              xPubBech32: xPubBech32,
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: payloadHex,
              requestedSignerRaw: ledgerPubAccount.dRepDerivation.value.dRepIdNewBech32,
              shouldHashPayload: true,
            );

            expect(drepData.hashPayload, equals(true));
          });
        });
      });

      group("Error Cases", () {
        test("address not found", () async {
          const payloadHex = "546869732069732061207465737420706179616f6164"; // "This is a test payaoad"
          final signer = (await ledgerPubAccount.paymentAddress(10, NetworkId.mainnet)).bech32Encoded;

          await expectLater(
              () => mapper.toParsedMessageData(
                    xPubBech32: xPubBech32,
                    accountIndex: 0,
                    deriveMaxAddressCount: 1, // we use address 10 but we only derive one address
                    messageHex: payloadHex,
                    requestedSignerRaw: signer,
                  ),
              throwsA(isA<SigningAddressNotFoundException>()));
        });
        test("should throw exception for invalid bech32 address", () async {
          await expectLater(
            () => mapper.toParsedMessageData(
              xPubBech32:
                  "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0",
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: "48656c6c6f", // "Hello"
              requestedSignerRaw:
                  "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp", // Invalid checksum
            ),
            throwsA(isA<InvalidChecksum>()),
          );
        });

        test("should throw SigningAddressNotValidException for invalid hex length", () async {
          await expectLater(
            () => mapper.toParsedMessageData(
              xPubBech32:
                  "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0",
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: "48656c6c6f",
              requestedSignerRaw: "123", // Invalid length
            ),
            throwsA(isA<SigningAddressNotValidException>()),
          );
        });

        test("should throw SigningAddressNotValidException for invalid hex length (too long)", () async {
          await expectLater(
            () => mapper.toParsedMessageData(
              xPubBech32:
                  "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0",
              accountIndex: 0,
              deriveMaxAddressCount: 10,
              messageHex: "48656c6c6f",
              requestedSignerRaw:
                  "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345", // Too long
            ),
            throwsA(isA<SigningAddressNotValidException>()),
          );
        });
      });
    });
  });
}
