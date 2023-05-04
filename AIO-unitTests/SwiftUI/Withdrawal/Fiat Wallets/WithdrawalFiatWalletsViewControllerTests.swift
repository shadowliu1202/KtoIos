import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalFiatWalletsViewControllerTests: XCTestCase {
  func test_HasThreeFiatWallets_ClickAddButton_DisplayAlert_KTO_TC_116() {
    let stubViewModel = mock(WithdrawalFiatWalletsViewModel.self)
      .initialize(
        withdrawalService: mock(AbsWithdrawalAppService.self),
        playerConfig: PlayerConfigurationImpl(supportLocale: .China()))
    let stubAlert = mock(AlertProtocol.self)

    given(stubViewModel.playerWallet) ~> .init(
      wallets: (0..<3).map {
        .init(
          walletId: "test \($0)",
          name: "Test \($0)",
          isDeletable: true,
          verifyStatus: .verified,
          bankAccount: .init(
            bankId: 0,
            branch: "",
            accountName: "",
            accountNumber: "",
            city: "",
            location: ""),
          limitation: .init(
            maxCount: 100,
            maxAmount: "1000".toAccountCurrency(),
            currentCount: 3,
            currentAmount: "10000".toAccountCurrency(),
            oneOffMinimumAmount: "10".toAccountCurrency(),
            oneOffMaximumAmount: "1000".toAccountCurrency()))
      },
      maxAmount: 3)

    let sut = WithdrawalFiatWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

    sut.popMaximumAlert()

    verify(
      stubAlert
        .show(
          any(),
          Localize.string("withdrawal_bankcard_add_overlimit", "3"),
          confirm: any(), confirmText: any(),
          cancel: any(), cancelText: any(),
          tintColor: any()))
      .wasCalled()
  }
}
