import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_sdk_ledger_interop/cardano_sdk_ledger_interop.dart";
import "package:cardano_sdk_ledger_interop/src/models/signature_request_data.dart";
import "package:ledger_cardano_plus/ledger_cardano_plus_models.dart";
import "package:test/test.dart";

// const timeout = Timeout(Duration(hours: 24));
const timeout = Timeout(Duration(seconds: 10));

// run with "flutter test" command
void main() async {
  const mapper = TransactionSigningLedgerMapper();
  const xPubBech32 =
      "xpub1pk2053yfw3fyn6wdnxwfqlexjtswt3avs69fvqcja4w5srze7twzxxkurm59wqlhzj47wrrdjhcz0emwa9rlxcwtku4p2kkgettdy0cfnl5k0";
  final ledgerPubAccount = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);
  group("mapping", () {
    test("jpg.store list NFT tx", () async {
      const txCbor =
          "84a60082825820f788fa07456aca73d6f5bec25392490a0f21259bbb1202cea6229b3a8a8ed10e00825820e1cbfa28fa543e01f9a5fa378054c5eb9ce5552f771623ec9bcd3edc20980d5300018283583931c727443d77df6cff95dca383994f4c3024d03ff56b02ecc22b0f3f652c967f4bd28944b06462e13c5e3f5d5fa6e03f8567569438cd833e6d821a0014b752a1581cd4473a78ae992ed6d95299e7177b45c8053d5db5495467a29ff0c780a1554d6f636f7373694d6167696350696c6c3030363336015820f069a76dc4fb6f93b065825d08fccbb53ef59105b50463362412da7fd9c7b1358258390114c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f11241d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61c1a0071ad28021a000327b5031a07e3430b075820f7efbc68ca0ca185c62b751bec24e8ced9b41be3846106b37fdc222d81c064d10b5820a0b73e780179b0819acdc069fc1400bdc3a776d0e2ca7a5afea5d4fb28423adba1049fd8799f9fd8799fd8799fd8799f581c7f5a90f7f3f870f6f8a9c8c88364ac0acfbf1c96331685c77b3edaf9ffd8799fd8799fd8799f581cb6fb9a1a65f67829e5fcd4836e9048100fecd76e7d28dcd59be6e2feffffffff1a002dc6c0ffd8799fd8799fd8799f581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f1124ffd8799fd8799fd8799f581c1d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61cffffffff1a05a995c0ffff581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f1124fffff5a8181e61361832784064383739396639666438373939666438373939666438373939663538316337663561393066376633663837306636663861396338633838333634616330616366183378406266316339363333313638356337376233656461663966666438373939666438373939666438373939663538316362366662396131613635663637383239653518347840666364343833366539303438313030666563643736653764323864636435396265366532666566666666666666663161303032646336633066666438373939661835784064383739396664383739396635383163313463313664376634333234336264383134373865363862396462353361383532386664346662313037386435386435183678403461376631313234666664383739396664383739396664383739396635383163316432323761656661346237373331343931373038383561616462613330616118377840623331323763633631316464626334393939646566363163666666666666666631613035613939356330666666663538316331346331366437663433323433621838782d64383134373865363862396462353361383532386664346662313037386435386435346137663131323466662c";
      final tx = CardanoTransaction.deserializeFromHex(txCbor);

      final ledgerReq = await mapper.toLedgerSigningRequest(
        tx: tx,
        networkId: NetworkId.mainnet,
        xPubBech32: xPubBech32,
        accountIndex: 0,
        maxDeriveAddressCount: 5,
        inputUtxoToAddress: {
          "091f2ca0cfe149844618c4083758bc9984a10f45ee791dad52dfbdf029bc0550#1":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
          "828313d913c42a9eafd7b8dbe931b1e85911a82be79c72d5aa2f64454805573e#0":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
          "f788fa07456aca73d6f5bec25392490a0f21259bbb1202cea6229b3a8a8ed10e#0":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
          "e1cbfa28fa543e01f9a5fa378054c5eb9ce5552f771623ec9bcd3edc20980d53#0":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
        },
      );

      final expectedLedgerReq = SignatureRequestData(
        ledgerSignRequest: ParsedSigningRequest(
          tx: ParsedTransaction(
            network: CardanoNetwork.mainnet(),
            inputs: [
              ParsedInput(
                txHashHex: "f788fa07456aca73d6f5bec25392490a0f21259bbb1202cea6229b3a8a8ed10e",
                outputIndex: 0,
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
              ),
              ParsedInput(
                txHashHex: "e1cbfa28fa543e01f9a5fa378054c5eb9ce5552f771623ec9bcd3edc20980d53",
                outputIndex: 0,
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
              ),
            ],
            outputs: [
              ParsedOutput.alonzo(
                amount: BigInt.from(1357650),
                tokenBundle: [
                  ParsedAssetGroup(
                    policyIdHex: "d4473a78ae992ed6d95299e7177b45c8053d5db5495467a29ff0c780",
                    tokens: [
                      ParsedToken(
                        assetNameHex: "4d6f636f7373694d6167696350696c6c3030363336",
                        amount: BigInt.from(1),
                      ),
                    ],
                  ),
                ],
                destination: ParsedOutputDestination.thirdParty(
                  addressHex:
                      "31c727443d77df6cff95dca383994f4c3024d03ff56b02ecc22b0f3f652c967f4bd28944b06462e13c5e3f5d5fa6e03f8567569438cd833e6d",
                ),
                datumHashHex: ParsedDatumHash(
                  datumHashHex: "f069a76dc4fb6f93b065825d08fccbb53ef59105b50463362412da7fd9c7b135",
                ),
              ),
              ParsedOutput.alonzo(
                amount: BigInt.from(7449896),
                destination: ParsedOutputDestination.deviceOwned(
                  addressParams: ParsedAddressParams.shelley(
                    shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                      spendingDataSource: SpendingDataSourcePath(
                        path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                      ),
                      stakingDataSource: StakingDataSource.keyPath(
                        path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            fee: BigInt.from(206773),
            ttl: BigInt.from(132334347),
            auxiliaryData: ParsedTxAuxiliaryData.arbitraryHash(
              hashHex: "f7efbc68ca0ca185c62b751bec24e8ced9b41be3846106b37fdc222d81c064d1",
            ),
            scriptDataHashHex: ScriptDataHash(
              hexString: "a0b73e780179b0819acdc069fc1400bdc3a776d0e2ca7a5afea5d4fb28423adb",
            ),
            includeNetworkId: false,
          ),
          signingMode: TransactionSigningModes.ordinaryTransaction,
          additionalWitnessPaths: [],
          options: ParsedTransactionOptions(tagCborSets: false),
        ),
        ledgerPubAccount: ledgerPubAccount,
      );

      expect(ledgerReq, equals(expectedLedgerReq));
    });

    test("complex tx", () async {
      const txCbor =
          "84a70082825820091f2ca0cfe149844618c4083758bc9984a10f45ee791dad52dfbdf029bc055001825820828313d913c42a9eafd7b8dbe931b1e85911a82be79c72d5aa2f64454805573e000183a3005839112025463437ee5d64e89814a66ce7f98cb184a66ae85a2fbbfd7501061d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61c01821a002625a0a1581c95a427e384527065f2f8946f5e86320d0117839a5e98ea2c0b55fb00a14448554e541a0044c695028201d81858fdd8799f4100581ce143245a4460683c3163858a1b6fbb0c45ffe770e6986cfd409b282cd8799f581c95a427e384527065f2f8946f5e86320d0117839a5e98ea2c0b55fb004448554e54ff1a0044c6951a0007a1201a00132cfdd8799f4040ffd8799f1a00132cfd1a0044c695ff00d8799fd8799f581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f1124ffd8799fd8799fd8799f581c1d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61cffffffff581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f11249f581c2f9ff04d8914bf64d671a03d34ab7937eb417831ea6b9f7fbcab96f5ffff82583901ffebcc9e31749eb5803e396202d84e3b436ec362463b2fd70fb4c8819086fc9117b2dadb43da1f922c46039a47d51bff09433dcdd18f1cce1a000f42408258390114c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f11241d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61c821a007ec3b2a2581c02f68378e37af4545d027d0a9fa5581ac682897a3fc1f6d8f936ed2ba15820446f6e7455736544656d6f576974685265616c414441206769746d616368746c01581c1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1ea150776f726c646d6f62696c65746f6b656e1a0001e791021a00038019031a07ddebd4075820360dded0dc97b71db4f18c3db30dc925293047f9370d96fbc2c8cf5335af4955081a07ddddc40e82581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f1124581c1d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61ca1049ffff5a11902a2a1636d7367826f44657868756e74657220547261646570506172746e6572205645535052694f53";
      final tx = CardanoTransaction.deserializeFromHex(txCbor);

      final ledgerReq = await mapper.toLedgerSigningRequest(
        tx: tx,
        networkId: NetworkId.mainnet,
        xPubBech32: xPubBech32,
        accountIndex: 0,
        maxDeriveAddressCount: 5,
        inputUtxoToAddress: {
          "091f2ca0cfe149844618c4083758bc9984a10f45ee791dad52dfbdf029bc0550#1":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
          "828313d913c42a9eafd7b8dbe931b1e85911a82be79c72d5aa2f64454805573e#0":
              "addr1qy2vzmtlgvjrhkq50rngh8d482zj3l20kyrc6kx4ffl3zfqayfawlf9hwv2fzuygt2km5v92kvf8e3s3mk7ynxw77cwqf7zhh2",
        },
      );

      final expectedLedgerReq = SignatureRequestData(
        ledgerSignRequest: ParsedSigningRequest(
          tx: ParsedTransaction(
            network: CardanoNetwork.mainnet(),
            inputs: [
              ParsedInput(
                txHashHex: "091f2ca0cfe149844618c4083758bc9984a10f45ee791dad52dfbdf029bc0550",
                outputIndex: 1,
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
              ),
              ParsedInput(
                txHashHex: "828313d913c42a9eafd7b8dbe931b1e85911a82be79c72d5aa2f64454805573e",
                outputIndex: 0,
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
              ),
            ],
            outputs: [
              ParsedOutput.babbage(
                amount: BigInt.from(2500000),
                tokenBundle: [
                  ParsedAssetGroup(
                    policyIdHex: "95a427e384527065f2f8946f5e86320d0117839a5e98ea2c0b55fb00",
                    tokens: [
                      ParsedToken(
                        assetNameHex: "48554e54",
                        amount: BigInt.from(4507285),
                      ),
                    ],
                  ),
                ],
                destination: ParsedOutputDestination.thirdParty(
                  addressHex:
                      "112025463437ee5d64e89814a66ce7f98cb184a66ae85a2fbbfd7501061d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61c",
                ),
                datum: ParsedDatum.inline(
                  datumHex:
                      "d8799f4100581ce143245a4460683c3163858a1b6fbb0c45ffe770e6986cfd409b282cd8799f581c95a427e384527065f2f8946f5e86320d0117839a5e98ea2c0b55fb004448554e54ff1a0044c6951a0007a1201a00132cfdd8799f4040ffd8799f1a00132cfd1a0044c695ff00d8799fd8799f581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f1124ffd8799fd8799fd8799f581c1d227aefa4b773149170885aadba30aab3127cc611ddbc4999def61cffffffff581c14c16d7f43243bd81478e68b9db53a8528fd4fb1078d58d54a7f11249f581c2f9ff04d8914bf64d671a03d34ab7937eb417831ea6b9f7fbcab96f5ffff",
                ),
              ),
              ParsedOutput.alonzo(
                destination: ParsedOutputDestination.thirdParty(
                  addressHex:
                      "01ffebcc9e31749eb5803e396202d84e3b436ec362463b2fd70fb4c8819086fc9117b2dadb43da1f922c46039a47d51bff09433dcdd18f1cce",
                ),
                amount: BigInt.from(1000000),
              ),
              ParsedOutput.alonzo(
                destination: ParsedOutputDestination.deviceOwned(
                  addressParams: ParsedAddressParams.shelley(
                    shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                      spendingDataSource: SpendingDataSourcePath(
                        path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                      ),
                      stakingDataSource: StakingDataSource.keyPath(
                        path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                      ),
                    ),
                  ),
                ),
                amount: BigInt.from(8307634),
                tokenBundle: [
                  ParsedAssetGroup(
                    policyIdHex: "02f68378e37af4545d027d0a9fa5581ac682897a3fc1f6d8f936ed2b",
                    tokens: [
                      ParsedToken(
                        assetNameHex: "446f6e7455736544656d6f576974685265616c414441206769746d616368746c",
                        amount: BigInt.from(1),
                      ),
                    ],
                  ),
                  ParsedAssetGroup(
                    policyIdHex: "1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e",
                    tokens: [
                      ParsedToken(
                        assetNameHex: "776f726c646d6f62696c65746f6b656e",
                        amount: BigInt.from(124817),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            fee: BigInt.from(229401),
            ttl: BigInt.from(131984340),
            auxiliaryData: ParsedTxAuxiliaryData.arbitraryHash(
              hashHex: "360dded0dc97b71db4f18c3db30dc925293047f9370d96fbc2c8cf5335af4955",
            ),
            validityIntervalStart: BigInt.from(131980740),
            includeNetworkId: false,
            requiredSigners: [
              ParsedRequiredSigner.path(
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
              ),
              ParsedRequiredSigner.path(
                path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
              ),
            ],
          ),
          signingMode: TransactionSigningModes.plutusTransaction,
          additionalWitnessPaths: [
            LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
            LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
          ],
          options: ParsedTransactionOptions(tagCborSets: false),
        ),
        ledgerPubAccount: ledgerPubAccount,
      );

      expect(ledgerReq, equals(expectedLedgerReq));
    });
  });

  group("check tx signature required", () {
    // based on issue reported on discord and signature found in the tx submission failure
    test(
      "reported issues #1",
      () async {
        const xPubBech32 =
            "xpub1m8k3509pmpjajnl630f56wtkrac9nw30p7edfvenxkzwl78ar62zvejs7qmze5wmqrwakgwdcmau422c7umhve2ahluelyxxkvk7ulcquemdm";
        final ledgerPubAccount = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xPubBech32);
        const txCbor =
            "84a5008182582089573606859d1c98863affe7c2a421a4944492fd4c063b6dae5b5059cb41bf53010182825839013b890bd8eb7a9df87f8d60bbe7f43ff6267dd68aba6930d6d9df0f64565c3595b84424b061125a49274df9e269c5455cf17debaa730fb1051a004c4b40825839013b890bd8eb7a9df87f8d60bbe7f43ff6267dd68aba6930d6d9df0f64565c3595b84424b061125a49274df9e269c5455cf17debaa730fb1051b000000057d4c58bf021a0002aa11031a08c3f4ea05a1581de1565c3595b84424b061125a49274df9e269c5455cf17debaa730fb1051a00f7259aa10081825820f6cf697579ab1de6093c6662697a46963fb9f72a89e52337aa9b1f0a6d2159ab5840b232147be4127bfd12daabedbf1e32747405c144251709fbcbc2a1e48c1be569b28f556100081c796a1c5e42fbcc5750c766c2e9e85e4c03f0d822ff27b54b06f5f6";

        final tx = CardanoTransaction.deserializeFromHex(txCbor);

        final ledgerReq = await mapper.toLedgerSigningRequest(
          tx: tx,
          networkId: NetworkId.mainnet,
          xPubBech32: xPubBech32,
          accountIndex: 0,
          maxDeriveAddressCount: 5,
          inputUtxoToAddress: {
            "89573606859d1c98863affe7c2a421a4944492fd4c063b6dae5b5059cb41bf53#1":
                "addr1qyacjz7cadafm7rl34sthel58lmzvlwk32axjvxkm80s7ezkts6etwzyyjcxzyj6fyn5m70zd8z52h830h465uc0kyzsqgwz8u",
          },
        );

        final expectedLedgerReq = SignatureRequestData(
          ledgerSignRequest: ParsedSigningRequest(
            tx: ParsedTransaction(
              network: CardanoNetwork.mainnet(),
              inputs: [
                ParsedInput(
                  txHashHex: "89573606859d1c98863affe7c2a421a4944492fd4c063b6dae5b5059cb41bf53",
                  outputIndex: 1,
                  path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                ),
              ],
              outputs: [
                ParsedOutput.alonzo(
                  amount: BigInt.from(5000000),
                  destination: ParsedOutputDestination.deviceOwned(
                    addressParams: ParsedAddressParams.shelley(
                      shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                        spendingDataSource: SpendingDataSourcePath(
                          path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                        ),
                        stakingDataSource: StakingDataSourceKey(
                          data: StakingDataSourceKeyData.path(
                            path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ParsedOutput.alonzo(
                  amount: BigInt.from(23576991935),
                  destination: ParsedOutputDestination.deviceOwned(
                    addressParams: ParsedAddressParams.shelley(
                      shelleyAddressParams: ShelleyAddressParamsData.basePaymentKeyStakeKey(
                        spendingDataSource: SpendingDataSourcePath(
                          path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.payment),
                        ),
                        stakingDataSource: StakingDataSourceKey(
                          data: StakingDataSourceKeyData.path(
                            path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              fee: BigInt.from(174609),
              ttl: BigInt.from(147059946),
              withdrawals: [
                ParsedWithdrawal(
                  stakeCredential: ParsedCredential.keyPath(
                    path: LedgerSigningPath.shelley(account: 0, address: 0, role: ShelleyAddressRole.stake),
                  ),
                  amount: BigInt.from(16197018),
                ),
              ],
              includeNetworkId: false,
            ),
            signingMode: TransactionSigningModes.ordinaryTransaction,
            additionalWitnessPaths: [],
            options: ParsedTransactionOptions(tagCborSets: false),
          ),
          ledgerPubAccount: ledgerPubAccount,
        );

        expect(ledgerReq, equals(expectedLedgerReq));
      },
      timeout: timeout,
    );
  });
}
