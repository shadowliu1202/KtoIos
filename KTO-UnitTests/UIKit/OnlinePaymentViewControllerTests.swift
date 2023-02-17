import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class OnlinePaymentViewControllerTests: XCTestCase {
  let onlinePayment = PaymentsDTO.Online(
    identity: "24",
    name: "数字人民币",
    hint: "",
    isRecommend: false,
    beneficiaries: Single<NSArray>.just([
      PaymentsDTO
        .Gateway(
          identity: "70",
          name: "JinYi_Digital",
          cash: CashType
            .Input(limitation: AmountRange(
              min: FiatFactory.shared.create(supportLocale: SupportLocale.China(), amount_: "200"),
              max: FiatFactory.shared.create(supportLocale: SupportLocale.China(), amount_: "2000")), isFloatAllowed: false),
          remitType: PaymentsDTO.RemitType.normal,
          remitBank: [],
          verifier: CompositeVerification<RemitApplication, PaymentError>(),
          hint: "",
          isAccountNumberDenied: true,
          isInstructionDisplayed: true),
      PaymentsDTO.Gateway(
        identity: "20",
        name: "JinYi_Crypto",
        cash: CashType.Input(
          limitation: AmountRange(
            min: FiatFactory.shared.create(supportLocale: SupportLocale.China(), amount_: "300"),
            max: FiatFactory.shared.create(supportLocale: SupportLocale.China(), amount_: "700")),
          isFloatAllowed: false),
        remitType: PaymentsDTO.RemitType.normal,
        remitBank: [],
        verifier: CompositeVerification<RemitApplication, PaymentError>(),
        hint: "",
        isAccountNumberDenied: true,
        isInstructionDisplayed: true)
    ] as NSArray).asWrapper())

  func test_givenDepositCountOverLimit_InDepositOnlinePaymentPage_thenAlertRequestLater() {
    injectStubCultureCode(.CN)

    let error = NSError(domain: "", code: 0, userInfo: ["statusCode": "10101", "errorMsg": ""])
    let playerDepositCountOverLimit = ExceptionFactory.create(error)

    let stubViewModel = mock(OnlineDepositViewModel.self)
      .initialize(selectedOnlinePayment: onlinePayment)

    given(stubViewModel.getRemitterName()) ~> .just("test")
    given(stubViewModel.errors()) ~> .just(playerDepositCountOverLimit)

    let stubAlert = mock(AlertProtocol.self)
    Alert.shared = stubAlert

    let sut = OnlinePaymentViewController.instantiate(
      selectedOnlinePayment: onlinePayment,
      viewModel: stubViewModel)

    sut.loadViewIfNeeded()

    stubViewModel.errorsSubject.onNext(error)

    verify(
      stubAlert.show(
        any(),
        "您有五个待处理的充值请求，请您过三分钟后再试",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }
}
