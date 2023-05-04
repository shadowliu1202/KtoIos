import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class OnlinePaymentViewControllerTests: XCTestCase {
  private func getFakeOnlinePaymentViewModel() -> OnlinePaymentViewModelMock {
    let stubViewModel = mock(OnlinePaymentViewModel.self)
      .initialize(
        mock(PlayerDataUseCase.self),
        Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
        getFakeHttpClient(),
        mock(PlayerConfiguration.self))

    given(stubViewModel.remitMethodName) ~> ""
    given(stubViewModel.gateways) ~> []
    given(stubViewModel.remitterName) ~> ""
    given(stubViewModel.remitInfoErrorMessage) ~> .empty
    given(stubViewModel.submitButtonDisable) ~> true
    given(stubViewModel.getSupportLocale()) ~> .China()
    given(stubViewModel.getTerminateAlertMessage()) ~> ""

    return stubViewModel
  }

  func test_whenNavigationPopBack_thenGetTerminateAlertMessageBeenCalled() {
    let stubViewModel = getFakeOnlinePaymentViewModel()

    let stubAlert = mock(AlertProtocol.self)
    Alert.shared = stubAlert

    let sut = OnlinePaymentViewController(
      selectedOnlinePayment: nil,
      viewModel: stubViewModel,
      alert: stubAlert)

    sut.loadViewIfNeeded()

    sut.back()

    verify(stubViewModel.getTerminateAlertMessage()).wasCalled()
  }

  func test_givenDepositCountOverLimit_InDepositOnlinePaymentPage_thenAlertRequestLater() {
    let error = NSError(
      domain: "",
      code: 0,
      userInfo: ["statusCode": "10101", "errorMsg": ""])

    let playerDepositCountOverLimitError = ExceptionFactory.create(error)

    let stubViewModel = getFakeOnlinePaymentViewModel()

    let stubAlert = mock(AlertProtocol.self)
    Alert.shared = stubAlert

    let sut = OnlinePaymentViewController(
      selectedOnlinePayment: nil,
      viewModel: stubViewModel,
      alert: stubAlert)

    sut.loadViewIfNeeded()

    stubViewModel.errorsSubject.onNext(playerDepositCountOverLimitError)

    verify(
      stubAlert.show(
        any(),
        any(
          String.self,
          where: { string in
            string.contains(Localize.string("deposit_notify_request_later"))
          }),
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }
}
