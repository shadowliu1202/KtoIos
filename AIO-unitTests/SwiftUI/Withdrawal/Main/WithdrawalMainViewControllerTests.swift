import Combine
import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalMainViewControllerTests: XCTestCase {
  private func getFakeWithdrawalMainViewModel() -> WithdrawalMainViewModelMock {
    let dummyWithdrawalAppService = Injectable.resolveWrapper(IWithdrawalAppService.self)
    let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
    let dummyWithdrawalUseCase = mock(WithdrawalUseCase.self)

    let fakeViewModel = mock(WithdrawalMainViewModel.self)
      .initialize(
        dummyWithdrawalAppService,
        dummyPlayerConfiguration)

    given(fakeViewModel.instruction) ~> nil
    given(fakeViewModel.recentRecords) ~> nil
    given(fakeViewModel.enableWithdrawal) ~> true
    given(fakeViewModel.allowedWithdrawalFiat) ~> nil
    given(fakeViewModel.allowedWithdrawalCrypto) ~> nil

    given(fakeViewModel.setupData()) ~> { }
    given(fakeViewModel.getSupportLocale()) ~> .China()

    given(fakeViewModel.errors()) ~> .empty()

    return fakeViewModel
  }

  func test_givenPlayerHasNoCryptoTurnOver_whenTapCryptoInfoButton_thenShowAlert_KTO_TC_6() {
    let mockAlert = mock(AlertProtocol.self)

    let sut = WithdrawalMainViewController.instance(alert: mockAlert)

    sut.loadViewIfNeeded()

    sut.alertCryptoLimitInformation()

    verify(mockAlert.show(
      Localize.string("cps_crpyto_withdrawal_requirement_title"),
      Localize.string("cps_crpyto_withdrawal_requirement_desc"),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled()
  }

  func test_givenHasCryptoTurnOver_whenTapFiatWithdrawal_thenShowAlert() {
    let stubViewModel = getFakeWithdrawalMainViewModel()
    let mockAlert = mock(AlertProtocol.self)

    let sut = WithdrawalMainViewController.instance(viewModel: stubViewModel, alert: mockAlert)

    given(stubViewModel.instruction) ~> .init(
      dailyAmountLimit: "",
      dailyMaxCount: "",
      turnoverRequirement: ("1,000", "CNY"),
      cryptoWithdrawalRequirement: nil)

    sut.loadViewIfNeeded()

    sut.alertCryptoWithdrawalNeeded()

    verify(mockAlert.show(
      Localize.string("cps_cash_withdrawal_lock_title"),
      Localize.string("cps_cash_withdrawal_lock_desc", "1,000CNY"),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled()
  }

  func test_givenPlayerIsNotValidForCryptoWithdrawal_whenTapCryptoWithdrawal_thenShowAlert() {
    let mockAlert = mock(AlertProtocol.self)

    let sut = WithdrawalMainViewController.instance(alert: mockAlert)

    sut.loadViewIfNeeded()

    sut.alertFiatWithdrawalNeeded()

    verify(mockAlert.show(
      any(),
      Localize.string("cps_withdrawal_all_fiat_first"),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled()
  }
}
