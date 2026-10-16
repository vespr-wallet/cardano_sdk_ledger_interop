import "package:cardano_sdk_ledger_interop/cardano_sdk_ledger_interop.dart";
import "package:cardano_sdk_ledger_interop/src/utils/signing_mode_utils.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
import "package:test/test.dart";

void main() {
  const hash28 = "11111111111111111111111111111111111111111111111111111111";
  const hash32 = "2222222222222222222222222222222222222222222222222222222222222222";
  final stakePath = LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake);
  final paymentPath = LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment);
  final keyPath = ParsedCredential.keyPath(path: stakePath);
  final keyHash = ParsedCredential.keyHash(keyHashHex: hash28);
  final scriptHash = ParsedCredential.scriptHash(scriptHashHex: hash28);

  ParsedInput input({LedgerSigningPath? path}) => ParsedInput(txHashHex: hash32, outputIndex: 0, path: path);
  final thirdPartyOutput = ParsedOutput.alonzo(
    destination: ParsedOutputDestination.thirdParty(addressHex: "61$hash28"),
    amount: BigInt.one,
  );
  final deviceOwnedOutput = ParsedOutput.alonzo(
    destination: ParsedOutputDestination.deviceOwned(
      addressParams: ParsedAddressParams.shelley(
        shelleyAddressParams: ShelleyAddressParamsData.enterpriseKey(
          spendingDataSource: SpendingDataSourcePath(path: paymentPath),
        ),
      ),
    ),
    amount: BigInt.one,
  );
  ParsedCertificate delegation(ParsedCredential credential) =>
      ParsedCertificate.stakeDelegation(stakeCredential: credential, poolKeyHashHex: hash28);
  ParsedWithdrawal withdrawal(ParsedCredential credential) =>
      ParsedWithdrawal(amount: BigInt.one, stakeCredential: credential);
  ParsedVoterVotes voter(ParsedVoter voter) => ParsedVoterVotes(voter: voter, votes: const []);

  ParsedTransaction tx({
    List<ParsedInput>? inputs,
    List<ParsedOutput>? outputs,
    List<ParsedCertificate>? certificates,
    List<ParsedWithdrawal>? withdrawals,
    List<ParsedVoterVotes>? votingProcedures,
    List<ParsedInput>? collateralInputs,
    ParsedOutput? collateralOutput,
    BigInt? totalCollateral,
    List<ParsedInput>? referenceInputs,
    List<ParsedRequiredSigner>? requiredSigners,
  }) =>
      ParsedTransaction(
        network: CardanoNetwork.mainnet(),
        inputs: inputs ?? [input(path: paymentPath)],
        outputs: outputs ?? [thirdPartyOutput],
        fee: BigInt.one,
        certificates: certificates,
        withdrawals: withdrawals,
        votingProcedures: votingProcedures,
        collateralInputs: collateralInputs,
        collateralOutput: collateralOutput,
        totalCollateral: totalCollateral,
        referenceInputs: referenceInputs,
        requiredSigners: requiredSigners,
      );

  const ordinary = TransactionSigningModes.ordinaryTransaction;
  const multisig = TransactionSigningModes.multisigTransaction;
  const plutus = TransactionSigningModes.plutusTransaction;

  final cases = <({String name, ParsedTransaction tx, TransactionSigningModes mode})>[
    (name: "plain payment", tx: tx(), mode: ordinary),
    (name: "third-party inputs only, nothing to witness", tx: tx(inputs: [input()]), mode: ordinary),
    (
      name: "key path certificate and withdrawal",
      tx: tx(certificates: [delegation(keyPath)], withdrawals: [withdrawal(keyPath)]),
      mode: ordinary,
    ),
    (
      name: "key path voter",
      tx: tx(votingProcedures: [voter(ParsedVoter.drepKeyPath(keyPath: stakePath))]),
      mode: ordinary,
    ),
    (name: "key hash withdrawal", tx: tx(withdrawals: [withdrawal(keyHash)]), mode: plutus),
    (
      name: "key hash voter",
      tx: tx(votingProcedures: [voter(ParsedVoter.drepKeyHash(keyHashHex: hash28))]),
      mode: plutus
    ),
    (name: "collateral inputs", tx: tx(collateralInputs: [input(path: paymentPath)]), mode: plutus),
    (name: "collateral output", tx: tx(collateralOutput: thirdPartyOutput), mode: plutus),
    (name: "total collateral", tx: tx(totalCollateral: BigInt.one), mode: plutus),
    (name: "reference inputs", tx: tx(referenceInputs: [input()]), mode: plutus),
    (name: "required signers", tx: tx(requiredSigners: [ParsedRequiredSigner.path(path: paymentPath)]), mode: plutus),
    (
      name: "script hash certificate with third-party inputs and outputs",
      tx: tx(inputs: [input()], certificates: [delegation(scriptHash)]),
      mode: multisig,
    ),
    (
      name: "script hash withdrawal and voter",
      tx: tx(
        inputs: [input()],
        withdrawals: [withdrawal(scriptHash)],
        votingProcedures: [voter(ParsedVoter.drepScriptHash(scriptHashHex: hash28))],
      ),
      mode: multisig,
    ),
    (
      name: "script hash certificate with a device-owned output",
      tx: tx(inputs: [input()], outputs: [deviceOwnedOutput], certificates: [delegation(scriptHash)]),
      mode: plutus,
    ),
    (name: "script hash certificate with a path input", tx: tx(certificates: [delegation(scriptHash)]), mode: plutus),
    (
      name: "script hash certificate with pool retirement",
      tx: tx(
        inputs: [input()],
        certificates: [
          delegation(scriptHash),
          ParsedCertificate.stakePoolRetirement(path: stakePath, retirementEpoch: BigInt.one),
        ],
      ),
      mode: plutus,
    ),
    (
      name: "mixed key path and script hash credentials",
      tx: tx(inputs: [input()], certificates: [delegation(keyPath)], withdrawals: [withdrawal(scriptHash)]),
      mode: plutus,
    ),
  ];

  for (final testCase in cases) {
    test(testCase.name, () => expect(determineSigningMode(testCase.tx), testCase.mode));
  }

  test("pool registration throws", () {
    final pool = ParsedPoolParams(
      poolKey: ParsedPoolKey.thirdParty(hashHex: hash28),
      vrfHashHex: hash32,
      pledge: BigInt.one,
      cost: BigInt.one,
      margin: ParsedMargin(numerator: BigInt.one, denominator: BigInt.two),
      rewardAccount: ParsedPoolRewardAccount.thirdParty(rewardAccountHex: "e1$hash28"),
      owners: const [],
      relays: const [],
      metadata: null,
    );
    expect(
      () => determineSigningMode(tx(certificates: [ParsedCertificate.stakePoolRegistration(pool: pool)])),
      throwsA(isA<InvalidTransactionError>()),
    );
  });
}
