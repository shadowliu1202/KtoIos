import Mockingbird
import RxBlocking
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionViewModelTests: XCBaseTestCase {
    func test_whenCallCashBackSettings_thenGetCashBackSettings() throws {
        let dummyPlayerUseCase = mock(PlayerDataUseCase.self)
        let stubPromotionUseCase = mock(PromotionUseCase.self)

        let cashBackSettings = [
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

        given(stubPromotionUseCase.getCashBackSettings(displayId: any())) ~> .just(cashBackSettings)

        let sut = PromotionViewModel(promotionUseCase: stubPromotionUseCase, playerUseCase: dummyPlayerUseCase)

        let expect = cashBackSettings

        let actual = try sut.getCashBackSettings(id: "")
            .toBlocking()
            .toArray()
            .first!

        XCTAssertEqual(expect, actual)
    }
}
