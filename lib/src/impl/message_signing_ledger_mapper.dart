import "package:cardano_dart_types/cardano_dart_types.dart";
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

    // if it's a bech32, convert it to hex
    final requestedSignerHex = ["addr", "stake", "drep", "cc_hot", "cc_cold"].any(requestedSignerRaw.startsWith)
        ? requestedSignerRaw.bech32ToHex()
        : requestedSignerRaw;

    // final requestedAddress = CardanoAddress.fromHexString(requestedSignerHex);

    ParsedMessageData dataFromAnyCreds(String credsHex) {
      final signingPath = derivedCredsToSigningPath[credsHex];
      if (signingPath == null) {
        throw SigningAddressNotFoundException(
          missingAddresses: {credsHex},
          searchedAddressesCount: deriveMaxAddressCount,
        );
      }

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
        // The device rebuilds the address from the paths, so only a key/key base address (header type 0) with our
        // own stake key is ours to sign for; anything else would be signed as a different address.
        CardanoAddressBase()
            when requestedSigningAddress.bytes.first >> 4 != 0 ||
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

    final data = switch (requestedSignerHex.length) {
      // Bare credential hex (payment, stake, DRep CIP-105, CC)
      56 => dataFromAnyCreds(requestedSignerHex),
      // 29 bytes: a reward or enterprise address, or a CIP-129 governance id (DRep, CC hot, CC cold). CIP-129 puts
      // the credential type in the header's low nibble as 2 (key hash) or 3 (script hash); addresses have 0 or 1.
      58 => requestedSignerHex.hexDecode().first & 0x0f > 1
          ? dataFromAnyCreds(requestedSignerHex.substring(2))
          : dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex)),
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
