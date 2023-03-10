import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension DepositRecordDetailViewModelProtocolMock: ObservableObject { }

extension DepositRecordDetailView.Row: Inspecting { }

final class DepositRecordDetailViewTests: XCTestCase {
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

  func test_PaymentStatusIsFloating_DisplayUploadButtonAndSubmitButton_KTO_TC_89() {
    let dummyLog = buildDummyLog(status: .floating)
    let stubViewModel = mock(DepositRecordDetailViewModelProtocol.self)

    given(stubViewModel.selectedImages) ~> []
    given(stubViewModel.isAllowConfirm) ~> false
    given(stubViewModel.log) ~> dummyLog.log
    given(stubViewModel.remarks) ~>
      dummyLog.updateHistories.map { .init(updateHistory: $0, host: "") }

    let sut = DepositRecordDetailView<DepositRecordDetailViewModelProtocolMock>
      .Row(type: .remark, shouldShowBottomLine: false)

    let expectation = sut.inspection.inspect { view in
      let selectVStack = try? view.vStack().vStack(0).tupleView(2).vStack(1)
      let submitBtn = try? selectVStack?.button(1)
      let uploadBtn = try? selectVStack?.vStack(0).button(2)

      XCTAssertNotNil(submitBtn)
      XCTAssertNotNil(uploadBtn)
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }
}
