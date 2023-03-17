import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension TransactionLogViewModelProtocolMock: ObservableObject { }
extension TransactionLogViewModelProtocolMock: Selecting {
  public var dataSource: [ktobet_asia_ios_qat.Selectable] { [] }
  public var selectedTitle: String { "" }
  public var selectedItems: [ktobet_asia_ios_qat.Selectable] {
    get { [] } set { }
  }
}

extension TransactionLogView.Sections: Inspecting { }
extension TransactionLogView.Summary: Inspecting { }

final class TransactionLogViewTests: XCTestCase {
  private func buildDummyBetLog(
    amount: Int,
    displayName: String,
    date: Date = .init())
    -> GeneralProduct
  {
    let dummyDetail = BalanceLogDetail(
      afterBalance: .zero(),
      amount: "\(amount)".toAccountCurrency(),
      date: date.convertToKotlinx_datetimeLocalDateTime(),
      wagerMappingId: "",
      productGroup: .UnSupport(),
      productType: .none,
      transactionType: .ProductBet(),
      remark: .None(),
      externalId: "")

    let dummyLog = GeneralProduct(
      transactionLog: dummyDetail,
      displayName: .init(title: KNLazyCompanion().create(input: displayName)))

    return dummyLog
  }

  func test_HasOneP2PBetLog_InTransactionLogPage_P2PLogIsDisplayedWithNumber1_KTO_TC_36() {
    injectStubCultureCode(.VN)

    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.sections) ~> [
      .init(
        model: "test",
        items: [
          self.buildDummyBetLog(
            amount: 100,
            displayName: Localize.string("common_p2p"))
        ])
    ]

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sections = try view
        .lazyVStack()
        .forEach(0)

      let numberOfSections = sections.count
      XCTAssertEqual(numberOfSections, 1)

      let sectionAt0 = try sections
        .tupleView(0)
        .vStack(1)
        .forEach(0)

      let numberOfRowAtSection0 = sectionAt0.count
      XCTAssertEqual(numberOfRowAtSection0, 1)

      let rowText = try sectionAt0
        .view(TransactionLogView<TransactionLogViewModelProtocolMock>.Row.self, 0)
        .find(text: "Đánh Bài Đối Kháng")

      XCTAssertNotNil(rowText)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasOnePositive100ProfitLog_InTransactionLogPage_LogIsDisplayedWithNumber1_KTO_TC_53() {
    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.sections) ~> [
      .init(
        model: "test",
        items: [
          self.buildDummyBetLog(
            amount: 100,
            displayName: "test")
        ])
    ]

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sections = try view
        .lazyVStack()
        .forEach(0)

      let numberOfSections = sections.count
      XCTAssertEqual(numberOfSections, 1)

      let sectionAt0 = try sections
        .tupleView(0)
        .vStack(1)
        .forEach(0)

      let numberOfRowAtSection0 = sectionAt0.count
      XCTAssertEqual(numberOfRowAtSection0, 1)

      let rowText = try sectionAt0
        .view(TransactionLogView<TransactionLogViewModelProtocolMock>.Row.self, 0)
        .find(text: "+100")

      XCTAssertNotNil(rowText)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasOneNegative100ProfitLog_InTransactionLogPage_LogIsDisplayedWithNumber1() {
    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.sections) ~> [
      .init(
        model: "test",
        items: [
          self.buildDummyBetLog(
            amount: -100,
            displayName: "test")
        ])
    ]

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sections = try view
        .lazyVStack()
        .forEach(0)

      let numberOfSections = sections.count
      XCTAssertEqual(numberOfSections, 1)

      let sectionAt0 = try sections
        .tupleView(0)
        .vStack(1)
        .forEach(0)

      let numberOfRowAtSection0 = sectionAt0.count
      XCTAssertEqual(numberOfRowAtSection0, 1)

      let rowText = try sectionAt0
        .view(TransactionLogView<TransactionLogViewModelProtocolMock>.Row.self, 0)
        .find(text: "-100")

      XCTAssertNotNil(rowText)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasPositive1000AndNegative100Summary_InTransactionLogPage_SummaryIsDisplayedPositive1000AndNegative100_KTO_TC_54() {
    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.summary) ~> .init(
      income: "1000".toAccountCurrency(),
      outcome: "100".toAccountCurrency())

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Summary()

    let expectation = sut.inspection.inspect { view in
      let vStack = try view.find(viewWithId: "FunctionalButton_Content_ID")
        .hStack()
        .vStack(2)

      let plus1000 = try vStack
        .localizedText(0)
        .string()

      XCTAssertEqual(plus1000, "+1,000")

      let minus100 = try vStack
        .localizedText(1)
        .string()

      XCTAssertEqual(minus100, "-100")
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasLogToday_SectionTitleIsToday() {
    injectStubCultureCode(.CN)

    let viewModel = TransactionLogViewModel(
      transactionLogUseCase: Injectable.resolveWrapper(TransactionLogUseCase.self))

    let stubSections = viewModel
      .buildSections([
        buildDummyBetLog(
          amount: 100,
          displayName: "test",
          date: .init())
      ])

    let expect = "今天"
    let actual = stubSections.first!.model
    XCTAssertEqual(expect, actual)
  }

  func test_HasLogToday_InTransactionLogPage_LogDateIsDisplayedWithToday_KTO_TC_55() {
    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.sections) ~> [
      .init(
        model: "今天",
        items: [
          self.buildDummyBetLog(
            amount: 100,
            displayName: "test")
        ])
    ]

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sectionTitle = try view
        .lazyVStack()
        .forEach(0)
        .tupleView(0)
        .localizedText(0)
        .string()

      XCTAssertEqual(sectionTitle, "今天")
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }

  func test_HasNoLog_InTransactionLogPage_ReminderIsDisplayed_KTO_TC_56() {
    injectStubCultureCode(.CN)

    let stubViewModel = mock(TransactionLogViewModelProtocol.self)

    given(stubViewModel.isPageLoading) ~> false
    given(stubViewModel.sections) ~> []

    let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections()

    let expectation = sut.inspection.inspect { view in
      let sectionTitle = try view
        .vStack()
        .localizedText(1)
        .string()

      XCTAssertEqual(sectionTitle, "暂无纪录")
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 30)
  }
}
