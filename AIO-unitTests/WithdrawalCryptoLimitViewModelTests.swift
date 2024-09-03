import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios

class WithdrawalCryptoLimitViewModelTests: XCBaseTestCase {
    func test_givenDepositTotalAmountIs10CNY_thenDisplayedDepositTotalAmount10CNY_KTO_TC_141() {
        let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

        let sut = WithdrawalCryptoLimitViewModel(stubWithdrawalAppService, dummyPlayerConfiguration)

        given(stubWithdrawalAppService.getCryptoTurnOverSummary()) ~> Single
            .just(WithdrawalDto.CryptoTurnOverSummary(
                remain: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                achieved: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                request: FiatFactory.shared.create(supportLocale: .China(), amount: "10"),
                requestLogs: [],
                achievedLogs: []))
            .asWrapper()

        sut.setupData()

        let expect = Localize.string("cps_total_require_amount", "10 CNY")

        let actual = sut.summaryRequirement?.title

        XCTAssertEqual(expect, actual)
    }

    func test_givenRemainWithdrawalRequirementIs10CNY_thenDisplayedRemainWithdrawalRequirement10CNY_KTO_TC_142() {
        let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

        let sut = WithdrawalCryptoLimitViewModel(stubWithdrawalAppService, dummyPlayerConfiguration)

        given(stubWithdrawalAppService.getCryptoTurnOverSummary()) ~> Single
            .just(WithdrawalDto.CryptoTurnOverSummary(
                remain: FiatFactory.shared.create(supportLocale: .China(), amount: "10"),
                achieved: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                request: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                requestLogs: [],
                achievedLogs: []))
            .asWrapper()

        sut.setupData()

        let expect = "10 CNY"

        let actual = sut.remainRequirement

        XCTAssertEqual(expect, actual)
    }

    func test_givenWithdrawalTotalAmountIs10CNY_thenDisplayedWithdrawalTotalAmount10CNY_KTO_TC_143() {
        let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

        let sut = WithdrawalCryptoLimitViewModel(stubWithdrawalAppService, dummyPlayerConfiguration)

        given(stubWithdrawalAppService.getCryptoTurnOverSummary()) ~> Single
            .just(WithdrawalDto.CryptoTurnOverSummary(
                remain: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                achieved: FiatFactory.shared.create(supportLocale: .China(), amount: "10"),
                request: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                requestLogs: [],
                achievedLogs: []))
            .asWrapper()

        sut.setupData()

        let expect = Localize.string("cps_total_completed_amount", "10 CNY")

        let actual = sut.summaryAchieved?.title

        XCTAssertEqual(expect, actual)
    }

    func test_givenOneDepositRecordWithAmount10CNY_thenDisplayedOneRecordWithPositiveSignedAmount_KTO_TC_144() {
        let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

        let sut = WithdrawalCryptoLimitViewModel(stubWithdrawalAppService, dummyPlayerConfiguration)

        given(stubWithdrawalAppService.getCryptoTurnOverSummary()) ~> Single
            .just(WithdrawalDto.CryptoTurnOverSummary(
                remain: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                achieved: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                request: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                requestLogs: [.init(
                    displayId: "",
                    cryptoAmount: CryptoFactory.shared.create(supportCryptoType: .usdt, amount: ""),
                    approvedDate: OffsetDateTime(
                        localDateTime: .init(
                            date: .init(year: 2023, month: .april, dayOfMonth: 10),
                            time: .init(hour: 15, minute: 0, second: 0, nanosecond: 0)),
                        timeZone: .fromFoundation(.current)).toInstant(),
                    fiatAmount: FiatFactory.shared.create(supportLocale: .China(), amount: "10"))],
                achievedLogs: []))
            .asWrapper()

        sut.setupData()

        let expect = "+10 CNY"

        let actual = sut.summaryRequirement?.records.first?.fiatAmount

        XCTAssertEqual(expect, actual)
    }

    func test_givenOneWithdrawalRecordWithAmount10CNY_thenDisplayedOneRecordWithNegativeSignedAmount_KTO_TC_145() {
        let stubWithdrawalAppService = mock(AbsWithdrawalAppService.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)

        let sut = WithdrawalCryptoLimitViewModel(stubWithdrawalAppService, dummyPlayerConfiguration)

        given(stubWithdrawalAppService.getCryptoTurnOverSummary()) ~> Single
            .just(WithdrawalDto.CryptoTurnOverSummary(
                remain: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                achieved: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                request: FiatFactory.shared.create(supportLocale: .China(), amount: ""),
                requestLogs: [],
                achievedLogs: [.init(
                    displayId: "",
                    cryptoAmount: CryptoFactory.shared.create(supportCryptoType: .usdt, amount: ""),
                    approvedDate: OffsetDateTime(
                        localDateTime: .init(
                            date: .init(year: 2023, month: .april, dayOfMonth: 10),
                            time: .init(hour: 15, minute: 0, second: 0, nanosecond: 0)),
                        timeZone: .fromFoundation(.current)).toInstant(),
                    fiatAmount: FiatFactory.shared.create(supportLocale: .China(), amount: "10"))]))
            .asWrapper()

        sut.setupData()

        let expect = "-10 CNY"

        let actual = sut.summaryAchieved?.records.first?.fiatAmount

        XCTAssertEqual(expect, actual)
    }
}
