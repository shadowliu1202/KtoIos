import Mockingbird
import RxBlocking
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionRepositoryImplTests: XCBaseTestCase {
  func test_whenGetCashBackSettings_thenReturnCashBackSettings() throws {
    let dummyHttpClient = getFakeHttpClient()
    let stubPromotionApi = mock(PromotionApi.self).initialize(dummyHttpClient)

    given(stubPromotionApi.getCashBackSettings(displayId: any())) ~> .just(
      ResponseDataList(
        statusCode: "200",
        errorMsg: "",
        data: [
          CashBackSettingBean(lossAmountRange: "100000~199999", maxAmount: "1888", cashBackPercentage: "1%"),
          CashBackSettingBean(lossAmountRange: "200000~499999", maxAmount: "6888", cashBackPercentage: "1.5%"),
          CashBackSettingBean(lossAmountRange: "500000~999999", maxAmount: "16888", cashBackPercentage: "2%"),
          CashBackSettingBean(lossAmountRange: "≥1000000", maxAmount: "28888", cashBackPercentage: "2.5%")
        ]))

    let sut = PromotionRepositoryImpl(stubPromotionApi)

    let expect = [
      CashBackSetting(
        cashBackPercentage: Percentage(percent: 1),
        lossAmountRange: "100000~199999",
        maxAmount: "1888".toAccountCurrency()),
      CashBackSetting(
        cashBackPercentage: Percentage(percent: 1.5),
        lossAmountRange: "200000~499999",
        maxAmount: "6888".toAccountCurrency()),
      CashBackSetting(
        cashBackPercentage: Percentage(percent: 2),
        lossAmountRange: "500000~999999",
        maxAmount: "16888".toAccountCurrency()),
      CashBackSetting(
        cashBackPercentage: Percentage(percent: 2.5),
        lossAmountRange: "≥1000000",
        maxAmount: "28888".toAccountCurrency())
    ]

    let actual = try sut.getCashBackSettings(displayId: "")
      .toBlocking()
      .toArray()
      .first!

    XCTAssertEqual(expect, actual)
  }
}
