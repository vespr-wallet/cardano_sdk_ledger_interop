import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "gov_action_id_x.dart";
import "voting_procedure_x.dart";

extension VotesX on Map<GovActionId, VotingProcedure> {
  List<ParsedVote> toParsedVotes() {
    return entries
        .map(
          (e) => ParsedVote(
            govActionId: e.key.toParsedGovActionId(),
            votingProcedure: e.value.toParsedVotingProcedure(),
          ),
        )
        .toList();
  }
}
