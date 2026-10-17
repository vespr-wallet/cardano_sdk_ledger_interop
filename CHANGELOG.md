# 0.7.0

- [Breaking] Updated `cardano_flutter_sdk` dependency to ^5.2.0 (`cardano_dart_types` 3.1.2)
- Adapted the voting procedures mapper to the new `VotingProcedures.voting` shape (each voter's votes paired with their CBOR length type)
- The transaction mapper fails closed on bodies Ledger can't reproduce, instead of letting the device sign a different body than the one submitted:
  - Proposal procedures (body key 20) throw `NotSupportedError`; they have no Ledger representation and were silently dropped
  - The body's metadata hash (key 7) is forwarded verbatim instead of being recomputed from the attached auxiliary data
  - The CBOR set tag (258) flag is derived from inputs, collateral, reference inputs, certificates and required signers; mixed encodings throw `NotSupportedError`
  - Bodies the device would re-encode differently throw `NotSupportedError` upfront: body or output map keys out of ascending order (`CardanoTransaction.hasAscendingBodyKeyOrder`), and indefinite-length CBOR lists, maps, byte strings or text strings anywhere in the body (`cardano_dart_types` 3.1 keeps the original encoding)
- [Breaking] Removed `cip08SignHashThreshold`. By default a message is hashed only when it does not fit the device's first chunk unhashed: 198 bytes when displayable as text, 99 bytes otherwise (`ledger_cardano_plus` limits). Plain-text messages between 50 and 198 bytes are no longer hashed by default; pass `shouldHashPayload` to force either behaviour
- Message signing for a base address requires a key/key header and the wallet's own stake key; a base address with a foreign stake credential or a script stake part throws `SigningAddressNotFoundException` instead of being signed as the wallet's base address
- CIP-129 constitutional committee hot and cold ids resolve to the wallet's CC keys; they were checked only against the DRep credential and reported as not found. The id's header is now validated: the key type must match the wallet key found behind it (`SigningAddressNotFoundException` otherwise), and script-hash or reserved headers throw `SigningAddressNotValidException`
- [Breaking] `SignedTransactionDataX.witnessesVKey` takes named `cardanoPubAcc` and `tx` arguments and throws `InvalidTransactionError` when the body hash the device signed differs from the hash of the transaction body as it serializes now (computed fresh, since `blake2bHash256Hex()` can return the hash cached at parse time even after `copyWith`), instead of returning witnesses for a different body
- The transaction mapper throws `InvalidTransactionError` when a spent input or collateral is at a wallet base address whose payment key is beyond `maxDeriveAddressCount`; such inputs were silently treated as third party and the transaction would have been submitted without their witness
- Byron witness paths throw `UnsupportedError` instead of returning the Shelley payment key as the witness vkey
- Removed the leftover `freezed` and `json_serializable` build configuration and the unused `build_runner` dev dependency

# 0.6.2

- Updated `ledger_cardano_plus` to ^0.6.1

# 0.6.1

- Updated `ledger_cardano_plus` to ^0.5.10
- Added Ledger Cardano app v8 mappings for combined Conway delegation certificates
- Fixed Conway stake deregistration certificate mapping

# 0.6.0

- [Breaking] Updated cardano_flutter_sdk dependency to ^4.0.0
- Adapted mappers to new SDK API

# 0.5.9

- Updated Cardano SDK dependency to ^3.0.0

# 0.5.8

- Added option to enforce whether payload should be hashed for MessageSigning

# 0.5.7

- Support for Ledger Message Signing mapping

# 0.5.6

- Removed freezed dependency

# [0.5.5+1] - June 30, 2025

- Improved and expanded the README documentation for open-source/public use. No code changes.

# [0.5.5] - June 30, 2025

## Changes

- Updated deps

# [0.5.3] - 20th of November 2024

## Bug Fixes

- Updated deps to fix build with latest cardano sdk version

# [0.5.2] - 3rd of October

## Bug Fixes

- Updated types version and fixed runtime issues

# [0.5.1] - 26th of September

## Bug Fixes

- Fixed stake credential being used always to sign certs (instead of stake/dRep/ccHot/ccCold as applicable)

# [0.5.0] - 26th of September

## Changes

- Updated cardano sdk to fix some conway cbor parsing/encoding bugs

# [0.4.2] - 25th of September

## Changes

- Updated tx mapper to include voting procedures

# [0.4.1] - 4th of September

## Changes

- Fixed tx mapping issues for the new governance keys

# [0.4.0] - 4th of September

## Changes

- [Breaking] Updated sdk and types dependencies
- Fixed some issues when identifying creds to sign with for drep and CC keys

# [0.3.1] - 26th of August

## Changes

- Updated sdk and types dependencies

# [0.3.0] - 26th of August

## Changes

- Updated sdk and types dependencies

# [0.2.3] - 20th of August

## BugFix

- Fixed outputs parsing looking at more device-owned addresses
- Updated ledger_cardano_plus

# [0.2.2] - 17th of August

## BugFix

- Included missing datum hash mapping for alonzo outputs

# [0.2.1] - 12th of August

## BugFix

- Corrected inline datum mapping

# [0.2.0] - 12th of August

- Updated to also return the ledger pub account when mapping to ledger signature request
- Added mapping from ledger signature to witness

# [0.1.0] - 25th of July

- Initial release
