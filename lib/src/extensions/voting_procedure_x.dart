import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

import "anchor_x.dart";
import "vote_x.dart";

extension VotingProcedureX on VotingProcedure {
  ParsedVotingProcedure toParsedVotingProcedure() => ParsedVotingProcedure(
        vote: vote.toVoteOption(),
        anchor: anchor?.toParsedAnchor(),
      );
}
