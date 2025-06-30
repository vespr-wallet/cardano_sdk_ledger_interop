import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension VoterX on Voter {
  ParsedVoter toParseVoter({
    required int accountIndex,
    required String dRepKeyHashHex,
    required String hotCredentialKeyHashHex,
    required String poolKeyHashHex,
  }) {
    final voterKeyHashHex = vKeyHash.hexEncode();
    return switch (voterType) {
      VoterType.CONSTITUTIONAL_COMMITTEE_HOT_KEY_HASH => voterKeyHashHex == hotCredentialKeyHashHex
          ? ParsedVoter.committeeKeyPath(
              keyPath: LedgerSigningPath.shelley(
                account: accountIndex,
                address: 0,
                role: ShelleyAddressRole.constitutionalCommitteeHot,
              ),
            )
          : ParsedVoter.committeeKeyHash(keyHashHex: vKeyHash.hexEncode()),
      VoterType.DREP_KEY_HASH => voterKeyHashHex == dRepKeyHashHex
          ? ParsedVoter.drepKeyPath(
              keyPath: LedgerSigningPath.shelley(
                account: accountIndex,
                address: 0,
                role: ShelleyAddressRole.drepCredential,
              ),
            )
          : ParsedVoter.drepKeyHash(keyHashHex: vKeyHash.hexEncode()),
      VoterType.STAKING_POOL_KEY_HASH => voterKeyHashHex == poolKeyHashHex
          ? ParsedVoter.stakePoolKeyPath(keyPath: throw UnimplementedError())
          : ParsedVoter.stakePoolKeyHash(keyHashHex: vKeyHash.hexEncode()),
      VoterType.CONSTITUTIONAL_COMMITTEE_HOT_SCRIPT_HASH => ParsedVoter.committeeScriptHash(
          scriptHashHex: vKeyHash.hexEncode(),
        ),
      VoterType.DREP_SCRIPT_HASH => ParsedVoter.drepScriptHash(
          scriptHashHex: vKeyHash.hexEncode(),
        ),
    };
  }
}
