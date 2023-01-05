import XCTest
import SwiftUI
import ViewInspector
import SharedBu
import Mockingbird

@testable import ktobet_asia_ios_qat

extension DepositCryptoRecordViewModelProtocolMock: ObservableObject { }

extension DepositCryptoRecordView.Header: Inspecting { }
extension DepositCryptoRecordView.Info: Inspecting { }

final class DepositCryptoRecordViewTest: XCTestCase {

    private let stubViewModel = mock(DepositCryptoRecordViewModelProtocol.self)
    
    override func tearDown() {
        reset(stubViewModel)
    }
    
    func test_PaymentStatusIsApproved_CpsInCompleteHintIsGone() {
        given(stubViewModel.header) ~> .init(fromCryptoName: "Test", showInCompleteHint: false)

        let sut = DepositCryptoRecordView<DepositCryptoRecordViewModelProtocolMock>.Header()

        let expectation = sut.inspection.inspect { view in
            let hintView = try? view
                .find(viewWithId: "headerCpsIncompleteHint")
                .localizedText()

            XCTAssertNil(hintView)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 30)
    }

    func test_PaymentStatusIsNotApproved_CpsInCompleteHintIsVisible() {
        given(stubViewModel.header) ~> .init(fromCryptoName: "Test", showInCompleteHint: true)

        let sut = DepositCryptoRecordView<DepositCryptoRecordViewModelProtocolMock>.Header()

        let expectation = sut.inspection.inspect { view in
            let hintView = try view
                .find(viewWithId: "headerCpsIncompleteHint")
                .localizedText()

            XCTAssertNotNil(hintView)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 30)
    }

    func test_RecordHasContent_InfoRowContentIsVisible() {
        let stubRecord = DepositCryptoRecord.Item(
            title: "Title",
            content: "Content"
        )

        given(stubViewModel.info) ~> [.info(stubRecord)]
        
        let sut = DepositCryptoRecordView<DepositCryptoRecordViewModelProtocolMock>.Info()

        let expectation = sut.inspection.inspect { view in
            let content = try? view
                .find(viewWithId: "infoRowContent")
                .localizedText()

            XCTAssertNotNil(content)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 30)
    }

    func test_RecordHasAttachmentContent_InfoRowAttachmentIsVisible() {
        let stubRecord = DepositCryptoRecord.Item(
            title: "Title",
            content: "Content",
            attachment: "Description"
        )
        
        given(stubViewModel.info) ~> [.info(stubRecord)]

        let sut = DepositCryptoRecordView<DepositCryptoRecordViewModelProtocolMock>.Info()

        let expectation = sut.inspection.inspect { view in
            let content = try? view
                .find(viewWithId: "infoRowAttachment")
                .localizedText()

            XCTAssertNotNil(content)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 30)
    }
    
    func test_PaymentStatusIsApprove_finalCryptoAmountTextColorIsOrangeFF8000() {
        let stubViewModel = DepositCryptoRecordViewModel(
            depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit()
        )
        
        let records = stubViewModel.generateRecords(generateCryptoLog(status: .approved))
        
        let tableRecord = records.first(where: { $0 == .table([], []) })
        
        guard case .table(_, let final) = tableRecord else {
            XCTFail("tableRecord should not be nil")
            return
        }
        
        XCTAssertTrue(final.contains(where: { $0.contentColor == .orangeFF8000 }))
    }
    
    func generateCryptoLog(status: PaymentStatus) -> PaymentLogDTO.CryptoLog {
        let log = PaymentLogDTO.Log(
            displayId: "TEST_" + "\(PaymentStatus.floating.self)",
            currencyType: .crypto,
            status: status,
            amount: "100".toAccountCurrency(),
            createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0)
        )
        let h1 = UpdateHistory(createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0), imageIds: [], remarkLevel1: "level01", remarkLevel2: "level02", remarkLevel3: "level03")
        let h2 = UpdateHistory(createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0), imageIds: [], remarkLevel1: "hi01", remarkLevel2: "hi02", remarkLevel3: "hi03")
        let exchangeRate = CryptoExchangeFactory.init().create(from: .usdt, to: SupportLocale.China(), exRate: "100")
        let requestMemo = ExchangeMemo(fromCrypto: "100".toCryptoCurrency(supportCryptoType: .usdt), rate: exchangeRate, toFiat: "100".toAccountCurrency(), date: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
        let actualMemo = requestMemo
        let memo = PaymentLogDTO.ProcessingMemo(request: requestMemo, actual: actualMemo, hashId: "TestHashId", toAddress: "TestAddress")
        let cryptoLog = PaymentLogDTO.CryptoLog(
            log: log,
            isTransactionComplete: true,
            updateUrl: Single<HttpUrl>.just(HttpUrl(url: "www.google.com")).asWrapper(),
            approvedDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            updateHistories: [h1, h2],
            processingMemo: memo)
        return cryptoLog
    }

}
