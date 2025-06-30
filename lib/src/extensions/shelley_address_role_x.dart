import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";

extension ShelleyAddressRoleX on ShelleyAddressRole {
  Bip32KeyRole get bip32KeyRole => switch (this) {
        ShelleyAddressRole.payment => Bip32KeyRole.payment,
        ShelleyAddressRole.change => Bip32KeyRole.change,
        ShelleyAddressRole.stake => Bip32KeyRole.staking,
        ShelleyAddressRole.drepCredential => Bip32KeyRole.drepCredential,
        ShelleyAddressRole.constitutionalCommitteeCold => Bip32KeyRole.constitutionalCommitteeCold,
        ShelleyAddressRole.constitutionalCommitteeHot => Bip32KeyRole.constitutionalCommitteeHot,
      };
}
