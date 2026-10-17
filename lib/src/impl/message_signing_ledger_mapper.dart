// AddressType is the ledger_cardano_plus enum: its value is the Shelley address header type nibble
import "package:cardano_dart_types/cardano_dart_types.dart" hide AddressType;
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../utils/derivation_utils.dart";

class MessageSigningLedgerMapper {
  const MessageSigningLedgerMapper();

  Future<ParsedMessageData> toParsedMessageData({
    required final String xPubBech32,
    required final int accountIndex,
    required final int deriveMaxAddressCount,
    required final String messageHex, // raw message hex
    required final String requestedSignerRaw, // expected bech32 or hex
    // if null, the message is hashed only when it doesn't fit the device's first chunk unhashed
    final bool? shouldHashPayload,
  }) async {
    final credsData = await DerivationUtils.deriveCredsToSigningPath(
      xPubBech32: xPubBech32,
      accountIndex: accountIndex,
      maxDeriveAddressCount: deriveMaxAddressCount,
    );

    final derivedCredsToSigningPath = credsData.derivedCredsToSigningPath;
    final stakeCredentialsHex = credsData.stakeCredentialsHex;
    // Resolved at the end when null: the unhashed size limit depends on how the device displays the message
    final hashPayload = shouldHashPayload ?? false;

    // if it's a bech32, keep its prefix and convert it to hex
    final bech32Hrp = ["addr", "stake", "drep", "cc_hot", "cc_cold"].any(requestedSignerRaw.startsWith)
        ? requestedSignerRaw.substring(0, requestedSignerRaw.lastIndexOf("1"))
        : null;
    final requestedSignerHex = bech32Hrp == null ? requestedSignerRaw : requestedSignerRaw.bech32ToHex();

    // A bech32 signer must carry the prefix of what its payload is (CIP-19 address, CIP-105 / CIP-129 id): a `drep1`
    // string wrapping a CC id or a reward address is malformed, not a request to sign with the key inside.
    void requireHrp(String? hrp) {
      if (bech32Hrp != null && hrp != null && bech32Hrp != hrp) {
        throw SigningAddressNotValidException(
          hexInvalidAddressOrCredential: requestedSignerHex,
          signingContext: "When signing payload message",
        );
      }
    }

    // CIP-105 / CIP-129 bech32 prefixes of the governance key types
    String? governanceHrp(ShelleyAddressRole role) => switch (role) {
          ShelleyAddressRole.drepCredential => "drep",
          ShelleyAddressRole.constitutionalCommitteeHot => "cc_hot",
          ShelleyAddressRole.constitutionalCommitteeCold => "cc_cold",
          // ponytail: bare payment and stake key hashes have no signData bech32 form, so their prefix is not checked
          ShelleyAddressRole.payment || ShelleyAddressRole.change || ShelleyAddressRole.stake => null,
        };

    ParsedMessageData dataFromAnyCreds(String credsHex) {
      final signingPath = derivedCredsToSigningPath[credsHex];
      if (signingPath == null) {
        throw SigningAddressNotFoundException(
          missingAddresses: {credsHex},
          searchedAddressesCount: deriveMaxAddressCount,
        );
      }
      requireHrp(governanceHrp(signingPath.role));

      final parsedAddressParams = switch (signingPath.role) {
        ShelleyAddressRole.payment || ShelleyAddressRole.change => ParsedAddressParams.shelley(
            shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
              spendingDataSource: SpendingDataSourcePath(path: signingPath),
              stakingDataSource: StakingDataSourceKey(
                data: StakingDataSourceKeyData.path(
                  // We'll just assume that staking path is the default one
                  path: LedgerSigningPath.shelley(account: accountIndex, address: 0, role: ShelleyAddressRole.stake),
                ),
              ),
            ),
          ),
        ShelleyAddressRole.stake => ParsedAddressParams.shelley(
            shelleyAddressParams: ShelleyAddressParamsData.rewardKey(
              stakingDataSource: StakingDataSourceKey(
                data: StakingDataSourceKeyData.path(path: signingPath),
              ),
            ),
          ),
        ShelleyAddressRole.drepCredential => null, // drep doesn't have address param
        ShelleyAddressRole.constitutionalCommitteeCold => null, // cc cold doesn't have address param
        ShelleyAddressRole.constitutionalCommitteeHot => null, // cc hot doesn't have address param
      };

      final parsedMessageData = parsedAddressParams != null
          ? ParsedMessageData.address(
              messageHex: messageHex,
              signingPath: signingPath,
              hashPayload: hashPayload,
              address: parsedAddressParams,
            )
          : ParsedMessageData.keyHash(
              // this is drep or cc signing
              messageHex: messageHex,
              signingPath: signingPath,
              hashPayload: hashPayload,
            );

      return parsedMessageData;
    }

    ParsedMessageData dataFromAddress(CardanoAddress requestedSigningAddress) {
      requireHrp(requestedSigningAddress.hrp);
      final LedgerSigningPath_Shelley signingPath = () {
        final path = derivedCredsToSigningPath[requestedSigningAddress.credentials];
        if (path != null) {
          return path;
        } else {
          throw SigningAddressNotFoundException(
            missingAddresses: {requestedSigningAddress.bech32Encoded},
            searchedAddressesCount: deriveMaxAddressCount,
          );
        }
      }();

      final parsedAddressParams = ParsedAddressParams.shelley(
          shelleyAddressParams: switch (requestedSigningAddress) {
        CardanoAddressReward() => ShelleyAddressParamsData.rewardKey(
            stakingDataSource: StakingDataSourceKey(
              data: StakingDataSourceKeyData.path(path: signingPath),
            ),
          ),
        CardanoAddressEnterprise() => ShelleyAddressParamsData.enterpriseKey(
            spendingDataSource: SpendingDataSourcePath(path: signingPath),
          ),
        // The device rebuilds the address from the paths, so only a key/key base address with our own stake key is
        // ours to sign for; anything else would be signed as a different address.
        CardanoAddressBase()
            when requestedSigningAddress.bytes.first >> 4 != AddressType.basePaymentKeyStakeKey.value ||
                requestedSigningAddress.stakeCredentials != stakeCredentialsHex =>
          throw SigningAddressNotFoundException(
            missingAddresses: {requestedSigningAddress.bech32Encoded},
            searchedAddressesCount: deriveMaxAddressCount,
          ),
        CardanoAddressBase() => ShelleyAddressParamsData.basePaymentKeyStakeKey(
            spendingDataSource: SpendingDataSourcePath(path: signingPath),
            stakingDataSource: StakingDataSourceKey(
              data: StakingDataSourceKeyData.path(
                path: LedgerSigningPath.shelley(account: accountIndex, address: 0, role: ShelleyAddressRole.stake),
              ),
            ),
          ),
        CardanoAddressByron() || CardanoAddressPointer() => throw UnexpectedSigningAddressTypeException(
            hexAddress: requestedSigningAddress.hexEncoded,
            type: requestedSigningAddress.addressType,
            signingContext: "MessageSigningLedgerMapper.toParsedMessageData()",
          ),
      });

      final parsedMessageData = ParsedMessageData.address(
        messageHex: messageHex,
        signingPath: signingPath,
        hashPayload: hashPayload,
        address: parsedAddressParams,
      );

      return parsedMessageData;
    }

    // CIP-129 id: the header's high nibble is the key type (0 CC hot, 1 CC cold, 2 DRep) and the low nibble the
    // credential type (2 key hash, 3 script hash). The key behind the id must be the wallet key of that type.
    ParsedMessageData dataFromGovernanceId(ShelleyAddressRole role) {
      requireHrp(governanceHrp(role));
      final signingPath = derivedCredsToSigningPath[requestedSignerHex.substring(2)];
      if (signingPath == null || signingPath.role != role) {
        throw SigningAddressNotFoundException(
          missingAddresses: {requestedSignerRaw},
          searchedAddressesCount: deriveMaxAddressCount,
        );
      }
      return ParsedMessageData.keyHash(messageHex: messageHex, signingPath: signingPath, hashPayload: hashPayload);
    }

    final data = switch (requestedSignerHex.length) {
      // Bare credential hex (payment, stake, DRep CIP-105, CC)
      56 => dataFromAnyCreds(requestedSignerHex),
      // 29 bytes: a CIP-129 governance id, or a reward or enterprise address (header low nibble 0 or 1)
      58 => switch (requestedSignerHex.hexDecode().first) {
          0x02 => dataFromGovernanceId(ShelleyAddressRole.constitutionalCommitteeHot),
          0x12 => dataFromGovernanceId(ShelleyAddressRole.constitutionalCommitteeCold),
          0x22 => dataFromGovernanceId(ShelleyAddressRole.drepCredential),
          // Script-hash ids and reserved key types: no Ledger key can sign for these
          final header when header & 0x0f > 1 => throw SigningAddressNotValidException(
              hexInvalidAddressOrCredential: requestedSignerHex,
              signingContext: "When signing payload message",
            ),
          _ => dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex)),
        },
      114 => dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex)),
      _ => throw SigningAddressNotValidException(
          hexInvalidAddressOrCredential: requestedSignerHex,
          signingContext: "When signing payload message",
        )
    };

    if (shouldHashPayload != null) return data;
    // An unhashed message must fit the device's first chunk, whose size depends on text vs hex display (isAscii)
    final maxUnhashedBytes = data.isAscii ? maxCIP8MessageFirstChunkAsciiSize : maxCIP8MessageFirstChunkHexSize;
    return messageHex.length ~/ 2 > maxUnhashedBytes ? data.copyWith(hashPayload: true) : data;
  }

  /// Converts the ledger device response to data signature
  ///
  /// Cross-reference the cose construction with {signCip8Data} below:
  /// https://github.com/input-output-hk/cardano-js-sdk/blob/master/packages/hardware-ledger/src/LedgerKeyAgent.ts
  Future<DataSignature> toDataSignature({
    required SignedMessageData data,
    required String payloadHex,
  }) async {
    final (signedPayloadBytes, hashed) = switch (data.signatureType) {
      DataSignatureType.paylod => (payloadHex.hexDecode(), false),
      DataSignatureType.payload_black2b_hash_28_bytes => (blake2bHash224(payloadHex.hexDecode()), true),
    };

    final headers = CoseHeaders(
      protectedHeader: CoseProtectedHeaderMap(
        bytes: CoseHeaderMap(
          algorithmId: const CborSmallInt(ALG_EdDSA),
          otherHeaders: CborMap.of({
            CborString(ADDRESS_KEY): CborBytes(data.addressFieldHex.hexDecode()),
          }),
        ).serializeAsBytes(),
      ),
      unprotectedHeader: CoseHeaderMap(hashed: hashed, otherHeaders: CborMap.of({})),
    );

    // final sigStructure = CoseSigStructure.fromSign1(
    //   bodyProtected: headers.protectedHeader,
    //   payload: payloadBytes,
    // );
    // final dataToSign = sigStructure.serializeAsBytes();

    final coseSign1 = CoseSign1(
      headers: headers,
      payload: signedPayloadBytes,
      signature: data.signatureHex.hexDecode(),
    );

    final coseKey = CoseKey(keyId: data.signingPublicKeyHex.hexDecode());

    return DataSignature(
      coseKeyHex: coseKey.serializeAsBytes().hexEncode(),
      coseSignHex: coseSign1.serializeAsBytes().hexEncode(),
    );
  }
}
