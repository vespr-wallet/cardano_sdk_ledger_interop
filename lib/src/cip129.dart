import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

/// CIP-129 governance id: one header byte followed by the 28-byte credential. The header's high nibble is the key
/// type ([Cip129KeyType]) and the low nibble the credential type ([Cip129CredentialType]).
enum Cip129KeyType {
  constitutionalCommitteeHot(0x0, hrp: "cc_hot", role: ShelleyAddressRole.constitutionalCommitteeHot),
  constitutionalCommitteeCold(0x1, hrp: "cc_cold", role: ShelleyAddressRole.constitutionalCommitteeCold),
  drep(0x2, hrp: "drep", role: ShelleyAddressRole.drepCredential);

  const Cip129KeyType(this.value, {required this.hrp, required this.role});

  /// Header high nibble
  final int value;

  /// Bech32 prefix of the id, also the CIP-105 prefix of the bare key hash
  final String hrp;

  /// The wallet key this type signs with
  final ShelleyAddressRole role;

  static Cip129KeyType? byHighNibble(int nibble) => values.where((type) => type.value == nibble).firstOrNull;

  static Cip129KeyType? byRole(ShelleyAddressRole role) => values.where((type) => type.role == role).firstOrNull;
}

enum Cip129CredentialType {
  keyHash(0x2),
  scriptHash(0x3);

  const Cip129CredentialType(this.value);

  /// Header low nibble. Reward and enterprise addresses, which are as long as a CIP-129 id, carry the network id
  /// (0 or 1) here instead.
  final int value;
}

/// Nibbles of a Shelley address or CIP-129 header byte
extension HeaderByteX on int {
  int get highNibble => this >> 4;
  int get lowNibble => this & 0x0f;
}
