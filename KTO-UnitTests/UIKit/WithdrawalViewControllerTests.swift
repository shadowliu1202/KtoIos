import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalViewControllerTests: XCTestCase {
  func test_NotQualifiedCryptoWithdrawal_ClickCryptoWithdrawalButton_PopNotQualifiedAlert_KTO_TC_57() {
    injectStubCultureCode(.CN)

    let stubBankCardViewModel = mock(ManageCryptoBankCardViewModel.self).initialize(
      withdrawalUseCase: mock(WithdrawalUseCase.self))

    given(stubBankCardViewModel.getCryptoBankCards()) ~> .just([])
    given(stubBankCardViewModel.isCryptoWithdrawalValid()) ~> .just(false)

    let stubAlert = mock(AlertProtocol.self)

    Alert.shared = stubAlert

    let sut = WithdrawalViewController.initFrom(storyboard: "Withdrawal")
    sut.bankCardViewModel = stubBankCardViewModel

    sut.crpytoTap(.init())

    verify(
      stubAlert.show(
        any(),
        "您需要先将人民币的金额提款完毕，才能提款虚拟币。",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }

  func test_QualifiedCryptoWithdrawal_ClickCryptoWithdrawalButton_WillGoToWithdrawalLandingPage() {
    injectStubCultureCode(.CN)
    injectStubPlayerLoginStatus(isLogin: true)

    let stubBankCardViewModel = mock(ManageCryptoBankCardViewModel.self).initialize(
      withdrawalUseCase: mock(WithdrawalUseCase.self))

    given(stubBankCardViewModel.getCryptoBankCards()) ~> .just([])
    given(stubBankCardViewModel.isCryptoWithdrawalValid()) ~> .just(true)

    let sut = WithdrawalViewController.initFrom(storyboard: "Withdrawal")
    sut.bankCardViewModel = stubBankCardViewModel

    makeItVisible(sut)

    sut.crpytoTap(.init())

    let presented = "\(type(of: sut.presentedViewController!))"
    XCTAssertEqual(presented, "WithdrawlLandingViewController")
  }
}
