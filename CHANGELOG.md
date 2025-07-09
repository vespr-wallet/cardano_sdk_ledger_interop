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
