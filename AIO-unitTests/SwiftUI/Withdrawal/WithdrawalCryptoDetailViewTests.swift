import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalCryptoRecordDetailView.Header: Inspecting { }

extension WithdrawalCryptoRecordDetailViewModelProtocolMock: ObservableObject { }

final class WithdrawalCryptoDetailViewTests: XCBaseTestCase {
  private func generateCryptoLog(status: WithdrawalDto.LogStatus) -> WithdrawalDto.CryptoLog {
    let withdrawalDtoLog: WithdrawalDto.Log = .init(
      displayId: "Test123",
      amount: "100".toAccountCurrency(),
      createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
      status: status,
      type: .crypto,
      isPendingHold: false)
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
    let memo = WithdrawalDto.ProcessingMemo(
      request: status == .approved ? requestMemo : nil,
      actual: status == .approved ? actualMemo : nil,
      hashId: status == .approved ? "TestHashId" : "",
      fromWalletAddress: "remitter address",
      toWalletAddress: "payee address")
    let log: WithdrawalDto.CryptoLog = .init(
      log: withdrawalDtoLog,
      isTransactionComplete: true,
      approvedDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
      updateHistories: [h1, h2],
      processingMemo: memo)

    return log
  }

  func test_PaymentStatusIsApprove_FinalCryptoAmountTextColorIsOrangeFF8000_KTO_TC_136() {
    let dummyLog = generateCryptoLog(status: .approved)

    let stubViewModel = WithdrawalCryptoRecordDetailViewModel(appService: Injectable.resolveWrapper(IWithdrawalAppService.self))

    let records = stubViewModel.generateRecords(dummyLog)

    let tableRecord = records.first(where: { $0 == .table([], []) })

    guard case .table(_, let final) = tableRecord else {
      XCTFail("tableRecord should not be nil")
      return
    }

    XCTAssertTrue(final.contains(where: { $0.contentColor == .alert }))
  }

  func test_PaymentStatusIsNotComplete_notCompleteHintIsDisplayed_KTO_TC_137() {
    injectStubCultureCode(.CN)

    let stubViewModel = mock(WithdrawalCryptoRecordDetailViewModelProtocol.self)

    given(stubViewModel.header) ~> CryptoRecordHeader(showUnCompleteHint: true)

    let sut = WithdrawalCryptoRecordDetailView<WithdrawalCryptoRecordDetailViewModelProtocolMock>.Header()

    let expectation = sut.inspection.inspect { view in
      let actual = try? view
        .vStack(0)
        .vStack(1)
        .localizedText(1)
        .string()

      XCTAssertEqual("以下列表若显示\" - \"状态，表示您尚未完成交易。", actual)
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }
}
