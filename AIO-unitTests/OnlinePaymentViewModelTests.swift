import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class OnlinePaymentViewModelTests: XCBaseTestCase {
  func test_givenChinaUser_whenNavigationPopback_thenAlertOnlinePaymentTerminate_KTO_TC_64() {
    stubLocalizeUtils(.China())

    let stubPlayerConfiguration = mock(PlayerConfiguration.self)
    given(stubPlayerConfiguration.supportLocale) ~> .China()

    let sut = OnlinePaymentViewModel(
      mock(PlayerDataUseCase.self),
      mock(AbsDepositAppService.self),
      getFakeHttpClient(),
      stubPlayerConfiguration)

    let actual = sut.getTerminateAlertMessage()

    XCTAssertTrue(actual.contains("在线充值将中断并结束。"))
  }

  func test_givenVietnameseUser_whenNavigationPopBack_thenAlertMessageContainsPaymentName_KTO_TC_65() {
    stubLocalizeUtils(.Vietnam())

    let stubPlayerConfiguration = mock(PlayerConfiguration.self)
    given(stubPlayerConfiguration.supportLocale) ~> .Vietnam()

    let sut = OnlinePaymentViewModel(
      mock(PlayerDataUseCase.self),
      mock(AbsDepositAppService.self),
      getFakeHttpClient(),
      stubPlayerConfiguration)

    let actual = sut.getTerminateAlertMessage()

    XCTAssertTrue(actual.contains("Gửi Tiền \"\(sut.remitMethodName)\" sẽ bị gián đoạn và kết thúc."))
  }

  func test_givenGatewayRemittanceAmountLimitOver999_whenRemittanceInput1_999_thenActualRemittance1999() {
    let dummyGatewayDTO = PaymentsDTO.Gateway(
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
      isInstructionDisplayed: true)

    let stubPlayerConfiguration = mock(PlayerConfiguration.self)
    given(stubPlayerConfiguration.supportLocale) ~> .Vietnam()

    let sut = OnlinePaymentViewModel(
      mock(PlayerDataUseCase.self),
      mock(AbsDepositAppService.self),
      getFakeHttpClient(),
      stubPlayerConfiguration)

    let remitApplication = sut.createOnlineRemitApplication(dummyGatewayDTO, .init(
      "",
      nil,
      "testRemitter",
      nil,
      "1,999"))

    let expect = "1999"
    let actual = remitApplication.remittance as! String

    XCTAssertEqual(expect, actual)
  }
}
