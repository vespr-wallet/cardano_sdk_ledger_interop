import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "voter_x.dart";
import "votes_x.dart";

extension VotingProceduresX on VotingProcedures {
  List<ParsedVoterVotes> toParsedVoterVotes({
    required int accountIndex,
    required String dRepKeyHashHex,
    required String hotCredentialKeyHashHex,
    required String poolKeyHashHex,
  }) =>
      voting.entries
          .map(
            (e) => ParsedVoterVotes(
              voter: e.key.toParseVoter(
                accountIndex: accountIndex,
                dRepKeyHashHex: dRepKeyHashHex,
                hotCredentialKeyHashHex: hotCredentialKeyHashHex,
                poolKeyHashHex: poolKeyHashHex,
              ),
              votes: e.value.toParsedVotes(),
            ),
          )
          .toList();
}
