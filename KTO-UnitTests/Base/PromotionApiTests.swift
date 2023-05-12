import Mockingbird
import RxBlocking
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionApiTests: XCBaseTestCase {
  let disposeBag = DisposeBag()

  func test_whenGetCashBackSettings_thenReturnCashBackSettingBean() throws {
    let stubHttpClient = stubHttpClientRequest(
      responseJsonString:
      """
      {
          "statusCode": "",
          "errorMsg": "",
          "errors": null,
          "node": "PC-LEONH",
          "data": [
              {
                  "lossAmountRange": "100000~199999",
                  "maxAmount": "1888",
                  "cashBackPercentage": "1%"
              },
              {
                  "lossAmountRange": "200000~499999",
                  "maxAmount": "6888",
                  "cashBackPercentage": "1.5%"
              },
              {
                  "lossAmountRange": "500000~999999",
                  "maxAmount": "16888",
                  "cashBackPercentage": "2%"
              },
              {
                  "lossAmountRange": "≥1000000",
                  "maxAmount": "28888",
                  "cashBackPercentage": "2.5%"
              }
          ]
      }
      """)

    let expect = [
      ResponseDataList(
        statusCode: "200",
        errorMsg: "",
        data: [
          CashBackSettingBean(lossAmountRange: "100000~199999", maxAmount: "1888", cashBackPercentage: "1%"),
          CashBackSettingBean(lossAmountRange: "200000~499999", maxAmount: "6888", cashBackPercentage: "1.5%"),
          CashBackSettingBean(lossAmountRange: "500000~999999", maxAmount: "16888", cashBackPercentage: "2%"),
          CashBackSettingBean(lossAmountRange: "≥1000000", maxAmount: "28888", cashBackPercentage: "2.5%")
        ])
    ]
    .first!
    .data

    let sut = PromotionApi(stubHttpClient)
    let actual = try sut.getCashBackSettings(displayId: "")
      .toBlocking()
      .toArray()
      .first!
      .data

    XCTAssertEqual(expect, actual)
  }
}
