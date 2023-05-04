import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalLogSummaryViewModelProtocolMock: ObservableObject { }
extension WithdrawalLogSummaryViewModelProtocolMock: Selecting {
  public var dataSource: [Selectable] { [] }
  public var selectedTitle: String { "" }
  public var selectedItems: [Selectable] {
    get { dataSource }
    set(newValue) { }
  }
}

extension WithdrawalLogSummaryView.Sections: Inspecting { }
extension WithdrawalLogSummaryView.Header: Inspecting { }

final class WithdrawalLogSummaryViewTests: XCTestCase {
  private func generateGroupLog(date: Date = .init(), count: Int = 1) -> WithdrawalDto.GroupLog {
    .init(
      groupDate: date.toUTCOffsetDateTime().toInstant(),
      logs: generateLog(date: date, count: count))
  }

  private func generateSections(date: Date = .init(), count: Int = 1) -> [WithdrawalLogSummaryViewModelProtocol.Section] {
    [
      .init(
        title: date.toDateString(),
        items: generateLog(date: date, count: count))
    ]
  }

  private func generateLog(date: Date = .init(), count: Int = 1) -> [WithdrawalDto.Log] {
    (0..<count).map {
      .init(
        displayId: "TEST_A\($0)",
        amount: "\($0 + 100)".toAccountCurrency(),
        createdDate: date.toUTCOffsetDateTime().toInstant(),
        status: .floating,
        type: .fiat,
        isPendingHold: false)
    }
  }

  func test_HasNoRecord_DisplayEmptyRemind_KTO_TC_138() {
    injectStubCultureCode(.CN)

    let stubViewModel = mock(WithdrawalLogSummaryViewModelProtocol.self)

    given(stubViewModel.sections) ~> []
    given(stubViewModel.isPageLoading) ~> false

    let sut = WithdrawalLogSummaryView<WithdrawalLogSummaryViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let reminder = try view
        .find(viewWithId: "emptyReminder")
        .vStack()

      let text = try reminder
        .localizedText(1)
        .string()

      XCTAssertNotNil(reminder)
      XCTAssertEqual("暂无纪录", text)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasOneRecord_DisplayOneRecord_KTO_TC_139() {
    let stubViewModel = mock(WithdrawalLogSummaryViewModelProtocol.self)

    let date = "2022/12/01".toDate(format: "yyyy/MM/dd", timeZone: Foundation.TimeZone(abbreviation: "UTC")!)!
    given(stubViewModel.sections) ~> self.generateSections(date: date)
    given(stubViewModel.isPageLoading) ~> false

    let sut = WithdrawalLogSummaryView<WithdrawalLogSummaryViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sections = try view
        .view(LogSections<WithdrawalDto.Log>.self)
        .vStack()
        .forEach(0)

      let numberOfSections = sections.count
      XCTAssertEqual(numberOfSections, 1)

      let section0Header = try view
        .find(viewWithId: "sectionHeader(at: 0)")
        .localizedText()
        .string()

      XCTAssertEqual(section0Header, "2022/12/01")

      let rows = try view
        .find(viewWithId: "section(at: 0)")
        .vStack()
        .forEach(0)

      let numberOfRows = rows.count
      XCTAssertEqual(numberOfRows, 1)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasLogToday_SectionTitleIsToday_KTO_TC_140() {
    injectStubCultureCode(.CN)

    let stubViewModel = WithdrawalLogSummaryViewModel(
      withdrawalService: Injectable.resolveWrapper(IWithdrawalAppService.self),
      playerConfig: PlayerConfigurationImpl(supportLocale: .China()))

    let stubSections = stubViewModel.buildSections([generateGroupLog(date: .init())])

    let expect = "今天"
    let actual = stubSections.first!.title

    XCTAssertEqual(expect, actual)
  }
}
