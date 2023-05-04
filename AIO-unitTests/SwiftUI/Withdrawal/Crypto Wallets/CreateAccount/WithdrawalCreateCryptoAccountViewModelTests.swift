import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalCreateCryptoAccountViewModelTests: XCTestCase {
  func test_givenPlayerHasThreeAccounts_thenPreFilledAccountAliasIsFour_KTO_TC_184() {
    let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
    let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

    let sut = WithdrawalCreateCryptoAccountViewModel(
      stubWithdrawalAppService,
      dummyPlayerConfiguration)

    let dummyCryptoWallet = WithdrawalDto.CryptoWallet(
      name: "",
      walletId: "",
      isDeletable: true,
      verifyStatus: .verified,
      type: .eth,
      network: .erc20,
      address: "",
      limitation: .init(
        maxCount: 5,
        maxAmount: FiatFactory.shared.create(
          supportLocale: .China(),
          amount_: ""),
        currentCount: 50,
        currentAmount: FiatFactory.shared.create(
          supportLocale: .China(),
          amount_: ""),
        oneOffMinimumAmount: FiatFactory.shared.create(
          supportLocale: .China(),
          amount_: ""),
        oneOffMaximumAmount: FiatFactory.shared.create(
          supportLocale: .China(),
          amount_: "")),
      remainTurnOver: FiatFactory.shared.create(
        supportLocale: .China(),
        amount_: ""))

    given(stubWithdrawalAppService.getWalletSupportCryptoTypes()) ~> [.usdc, .eth]

    given(stubWithdrawalAppService.getCryptoWallets()) ~> Observable
      .just(
        WithdrawalDto.PlayerCryptoWallet(
          wallets: [
            dummyCryptoWallet,
            dummyCryptoWallet,
            dummyCryptoWallet
          ],
          maxAmount: 100))
      .asWrapper()

    sut.setup()

    let expect = Localize.string("cps_default_bank_card_name") + "4"

    let actual = sut.accountAlias

    XCTAssertEqual(expect, actual)
  }
}
