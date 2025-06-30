import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension VoteX on Vote {
  VoteOption toVoteOption() => switch (this) {
        Vote.no => VoteOption.no,
        Vote.yes => VoteOption.yes,
        Vote.abstain => VoteOption.abstain,
      };
}
