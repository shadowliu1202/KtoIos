import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

extension DepositCryptoRecordDetailViewModelProtocolMock: ObservableObject { }

extension DepositCryptoRecordDetailView.Header: Inspecting { }
extension DepositCryptoRecordDetailView.Info: Inspecting { }

final class DepositCryptoRecordViewTest: XCBaseTestCase {
    private let stubViewModel = mock(DepositCryptoRecordDetailViewModelProtocol.self)

    override func tearDown() {
        reset(stubViewModel)
    }

    func generateCryptoLog(status: PaymentStatus) -> PaymentLogDTO.CryptoLog {
        let log = PaymentLogDTO.Log(
            displayId: "TEST_" + "\(PaymentStatus.floating.self)",
            currencyType: .crypto,
            status: status,
            amount: "100".toAccountCurrency(),
            createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
        let h1 = UpdateHistory(
            createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            imageIds: [],
            remarkLevel1: "level01",
            remarkLevel2: "level02",
            remarkLevel3: "level03")
        let h2 = UpdateHistory(
            createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            imageIds: [],
            remarkLevel1: "hi01",
            remarkLevel2: "hi02",
            remarkLevel3: "hi03")
        let exchangeRate = CryptoExchangeFactory().create(from: .usdt, to: SupportLocale.China(), exRate: "100")
        let requestMemo = ExchangeMemo(
            fromCrypto: "100".toCryptoCurrency(supportCryptoType: .usdt),
            rate: exchangeRate,
            toFiat: "100".toAccountCurrency(),
            date: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
        let actualMemo = requestMemo
        let memo = PaymentLogDTO.ProcessingMemo(
            request: requestMemo,
            actual: actualMemo,
            hashId: "TestHashId",
            toAddress: "TestAddress")
        let cryptoLog = PaymentLogDTO.CryptoLog(
            log: log,
            isTransactionComplete: true,
            updateUrl: Single<HttpUrl>.just(HttpUrl(url: "www.google.com")).asWrapper(),
            approvedDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            updateHistories: [h1, h2],
            processingMemo: memo)
        return cryptoLog
    }

    func test_PaymentStatusIsApproved_CpsUnCompleteHintIsGone() {
        given(stubViewModel.header) ~> .init(fromCryptoName: "Test", showUnCompleteHint: false)

        let sut = DepositCryptoRecordDetailView<DepositCryptoRecordDetailViewModelProtocolMock>.Header()

        let expectation = sut.inspection.inspect { view in
            let hintView = try? view
                .find(viewWithId: "headerCpsUnCompleteHint")
                .modifier(VisibilityModifier.self)
                .viewModifierContent()

            XCTAssertNil(hintView)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 60)
    }

    func test_PaymentStatusIsNotApproved_CpsUnCompleteHintIsVisible() {
        given(stubViewModel.header) ~> .init(fromCryptoName: "Test", showUnCompleteHint: true)

        let sut = DepositCryptoRecordDetailView<DepositCryptoRecordDetailViewModelProtocolMock>.Header()

        let expectation = sut.inspection.inspect { view in
            let hintView = try view
                .find(viewWithId: "headerCpsUnCompleteHint")
                .localizedText()

            XCTAssertNotNil(hintView)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 30)
    }
}
