import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension DepositRecordDetailViewModelProtocolMock: ObservableObject { }

extension DepositRecordDetailView: Inspecting { }

final class DepositRecordDetailViewTests: XCBaseTestCase {
  func buildDummyLog(status: PaymentStatus) -> PaymentLogDTO.FiatLog {
    .init(
      log: .init(
        displayId: "TestId",
        currencyType: .fiat,
        status: status,
        amount: 100.toAccountCurrency(),
        createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
        updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0)),
      approvedDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
      updateHistories: [
        .init(
          createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
          imageIds: [],
          remarkLevel1: "remarkLevel1",
          remarkLevel2: "remarkLevel2",
          remarkLevel3: "remarkLevel3"),
      ])
  }

  func stubViewModel() -> DepositRecordDetailViewModelProtocolMock {
    let stubViewModel = mock(DepositRecordDetailViewModelProtocol.self)
    given(stubViewModel.supportLocale) ~> .China()
    given(stubViewModel.selectedImages) ~> []
    given(stubViewModel.isAllowConfirm) ~> false
    return stubViewModel
  }

  func test_PaymentStatusIsFloating_DisplayUploadButtonAndSubmitButton_KTO_TC_89() {
    let dummyLog = buildDummyLog(status: .floating)
    let stubViewModel = stubViewModel()

    given(stubViewModel.log) ~> dummyLog.log
    given(stubViewModel.remarks) ~>
      dummyLog.updateHistories.map { .init(updateHistory: $0, host: "") }

    let sut = DepositRecordDetailView(
      viewModel: stubViewModel,
      transactionId: "")

    let expectation = sut.inspection.inspect { view in
      let submitBtn = try? view.find(button: "送出")
      let uploadBtn = try? view.find(button: "点击上传图片")

      XCTAssertNotNil(submitBtn)
      XCTAssertNotNil(uploadBtn)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }
}
