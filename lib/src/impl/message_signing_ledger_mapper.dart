import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "../utils/derivation_utils.dart";

const cip08SignHashThreshold = 100; // 100 hex characters

bool _shouldHashPayload(String messageHex) => messageHex.length >= cip08SignHashThreshold;

class MessageSigningLedgerMapper {
  const MessageSigningLedgerMapper();

  Future<ParsedMessageData> toParsedMessageData({
    required String xPubBech32,
    required int accountIndex,
    required int deriveMaxAddressCount,
    required String messageHex,
    required String requestedSignerRaw, // expected bech32 or hex
  }) async {
    final credsData = await DerivationUtils.deriveCredsToSigningPath(
      xPubBech32: xPubBech32,
      accountIndex: accountIndex,
      maxDeriveAddressCount: deriveMaxAddressCount,
    );

    final derivedCredsToSigningPath = credsData.derivedCredsToSigningPath;
    final dRepCredentialsHex = credsData.dRepCredentialsHex;
    final hashPayload = _shouldHashPayload(messageHex);

    // if it's a bech32, convert it to hex
    final requestedSignerHex = ["addr", "stake", "drep", "cc_hot", "cc_cold"].any(requestedSignerRaw.startsWith)
        ? requestedSignerRaw.bech32ToHex()
        : requestedSignerRaw;

    // final requestedAddress = CardanoAddress.fromHexString(requestedSignerHex);

    ParsedMessageData dataFromAddress(CardanoAddress requestedSigningAddress) {
      final LedgerSigningPath_Shelley signingPath = () {
        final path = derivedCredsToSigningPath[requestedSigningAddress.credentials];
        if (path != null) {
          return path;
        } else {
          throw SigningAddressNotFoundException(
            missingAddresses: {requestedSigningAddress.bech32Encoded},
            searchedAddressesCount: 1,
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
        CardanoAddressBase() => ShelleyAddressParamsData.basePaymentKeyStakeKey(
            spendingDataSource: SpendingDataSourcePath(path: signingPath),
            stakingDataSource: StakingDataSourceKey(
              data: StakingDataSourceKeyData.path(
                // We'll just assume that staking path is the default one
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

    ParsedMessageData dataFromDrepIdOrCreds(
      /// dRep ID (CIP-105) = Credentials Hex
      /// dRep ID (CIP-129) = Some Type Header + Credentials Hex
      String drepIdOrCredsHex,
    ) {
      if (!drepIdOrCredsHex.endsWith(dRepCredentialsHex)) {
        throw SigningAddressNotFoundException(
          missingAddresses: {requestedSignerRaw},
          searchedAddressesCount: 1,
        );
      }

      return ParsedMessageData.keyHash(
        messageHex: messageHex,
        signingPath: credsData.dRepSigningPath,
        hashPayload: hashPayload,
        preferHexDisplay: false,
      );
    }

    final data = switch (requestedSignerHex.length) {
      // This is used for dRep (CIP-95)
      //
      // NOTE: In the future, we can maybe also check against any other payment/change/stake/cc credentials
      //   (since the 56 bytes creds do not include the header which tells us the creds type)
      56 => dataFromDrepIdOrCreds(requestedSignerHex),
      // 58 or 114 is the length of the stake or receive address hex
      58 => () {
          final requestedSignerBytes = requestedSignerHex.hexDecode();
          final headerBytes = requestedSignerBytes[0];
          return headerBytes & 0x0f > 1
              ? dataFromDrepIdOrCreds(requestedSignerHex)
              : dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex));
        }(),
      114 => dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex)),
      _ => throw SigningAddressNotValidException(
          hexInvalidAddressOrCredential: requestedSignerHex,
          signingContext: "When signing payload message",
        )
    };

    return data;
  }

  /// Converts the ledger device response to data signature
  ///
  /// Cross-reference the cose construction with {signCip8Data} below:
  /// https://github.com/input-output-hk/cardano-js-sdk/blob/master/packages/hardware-ledger/src/LedgerKeyAgent.ts
  static Future<DataSignature> toDataSignature({
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
