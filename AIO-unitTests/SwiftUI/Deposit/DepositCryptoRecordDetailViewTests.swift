import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension DepositCryptoRecordDetailViewModelProtocolMock: ObservableObject { }

final class DepositCryptoRecordDetailViewTests: XCBaseTestCase {
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
      request: status == .approved ? requestMemo : nil,
      actual: status == .approved ? actualMemo : nil,
      hashId: status == .approved ? "TestHashId" : "",
      toAddress: status == .approved ? "TestAddress" : "")
    let cryptoLog = PaymentLogDTO.CryptoLog(
      log: log,
      isTransactionComplete: status == .approved,
      updateUrl: Single<HttpUrl>.just(HttpUrl(url: "www.google.com")).asWrapper(),
      approvedDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
      updateHistories: [h1, h2],
      processingMemo: memo)
    return cryptoLog
  }

  func test_PaymentStatusIsApprove_FinalCryptoAmountTextColorIsOrangeFF8000_KTO_TC_92() {
    let stubViewModel = DepositCryptoRecordDetailViewModel(
      depositService: mock(AbsDepositAppService.self))

    let records = stubViewModel.generateRecords(
      generateCryptoLog(status: .approved),
      submitTransactionIdOnClick: nil)

    let tableRecord = records.first(where: { $0 == .table([], []) })

    guard case .table(_, let final) = tableRecord else {
      XCTFail("tableRecord should not be nil")
      return
    }

    XCTAssertTrue(final.contains(where: { $0.contentColor == .orangeFF8000 }))
  }

  func test_PaymentStatusIsFloating_ShouldDisplayUploadFileLink_KTO_TC_93() {
    let stubViewModel = DepositCryptoRecordDetailViewModel(
      depositService: mock(AbsDepositAppService.self))

    let records = stubViewModel.generateRecords(
      self.generateCryptoLog(status: .floating),
      submitTransactionIdOnClick: nil)

    let hasLink = records
      .filter {
        if case .link = $0 {
          return true
        }
        else {
          return false
        }
      }
      .count == 1

    XCTAssertTrue(hasLink)
  }

  func test_RecordHasAttachmentContent_InfoRowAttachmentIsVisible() {
    let stubViewModel = mock(DepositCryptoRecordDetailViewModelProtocol.self)
    let stubRecord = CryptoRecord.LinkItem(
      title: "Title",
      content: "Content",
      attachment: "Upload")

    given(stubViewModel.info) ~> [.link(stubRecord)]

    let sut = DepositCryptoRecordDetailView<DepositCryptoRecordDetailViewModelProtocolMock>.Info()

    let expectation = sut.inspection.inspect { view in
      let content = try? view
        .find(viewWithId: "infoRowAttachment")
        .vStack(0)
        .localizedText(1)
        .find(text: "Upload")

      XCTAssertNotNil(content)
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_PaymentStatusIsNotApprove_FieldShouldDisplayDash_KTO_TC_94() {
    let stubViewModel = DepositCryptoRecordDetailViewModel(
      depositService: mock(AbsDepositAppService.self))

    let records = stubViewModel.generateRecords(
      self.generateCryptoLog(status: .pending),
      submitTransactionIdOnClick: nil)

    let filtered = records
      .compactMap { record -> [CryptoRecord.Item]? in

        switch record {
        case .info(let item):
          return [item]
        case .table(let applyItems, let finalItems):
          return applyItems + finalItems
        default:
          return nil
        }
      }
      .flatMap { $0 }
      .filter {
        $0.content != nil &&
          $0.title != Localize.string("common_applytime") &&
          $0.title != Localize.string("activity_status") &&
          $0.title != Localize.string("balancelog_detail_id")
      }

    let isAllDash = filtered.filter { $0.content != "-" }.isEmpty

    XCTAssertTrue(isAllDash)
  }

  func test_RecordHasContent_InfoRowContentIsCorrect() {
    let stubViewModel = mock(DepositCryptoRecordDetailViewModelProtocol.self)
    let stubRecord = CryptoRecord.Item(
      title: "Title",
      content: "Content")

    given(stubViewModel.info) ~> [.info(stubRecord)]

    let sut = DepositCryptoRecordDetailView<DepositCryptoRecordDetailViewModelProtocolMock>.Info()

    let expectation = sut.inspection.inspect { view in
      let content = try? view
        .find(viewWithId: "infoRowContent")
        .vStack(0)
        .localizedText(2)
        .find(text: "Content")

      XCTAssertEqual(try! content?.string(), "Content")
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }
}
