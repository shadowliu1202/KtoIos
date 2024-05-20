import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalRecordDetailViewModelProtocolMock: ObservableObject { }

extension WithdrawalRecordDetailView: Inspecting { }

final class WithdrawalRecordDetailViewTests: XCBaseTestCase {
  func buildDummyLog(status: WithdrawalDto.LogStatus) -> WithdrawalDto.FiatLog {
    .init(
      log: .init(
        displayId: "",
        amount: "100".toAccountCurrency(),
        createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
        status: status,
        type: .fiat,
        isBankProcessing: false),
      isCancelable: true,
      isNeedDocument: true,
      updated: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
      updateHistories: [
        .init(
          createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
          imageIds: [],
          remarkLevel1: "remarkLevel1",
          remarkLevel2: "remarkLevel2",
          remarkLevel3: "remarkLevel3")
      ])
  }

  func stubViewModel() -> WithdrawalRecordDetailViewModelProtocolMock {
    let stubViewModel = mock(WithdrawalRecordDetailViewModelProtocol.self)
    given(stubViewModel.supportLocale) ~> .China()
    given(stubViewModel.httpHeaders) ~> [:]
    given(stubViewModel.selectedImages) ~> []
    given(stubViewModel.isAllowConfirm) ~> false
    given(stubViewModel.isCancelable) ~> true
    given(stubViewModel.isSubmitButtonDisable) ~> false
    return stubViewModel
  }

  func test_PaymentStatusIsFloating_DisplayUploadButtonAndSubmitButton_KTO_TC_134() {
    stubLocalizeUtils(.China())

    let dummyLog = buildDummyLog(status: .floating)
    let stubViewModel = stubViewModel()

    given(stubViewModel.log) ~> dummyLog.log
    given(stubViewModel.remarks) ~>
      dummyLog.updateHistories.map { .init(updateHistory: $0, host: "") }

    let sut = WithdrawalRecordDetailView(
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
