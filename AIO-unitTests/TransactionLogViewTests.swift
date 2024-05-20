import Combine
import Mockingbird
import sharedbu
import SwiftUI
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

final class TransactionLogViewTests: XCBaseTestCase {
    private let dummySubject = PassthroughSubject<TransactionDTO.Log, Never>()
  
    private func buildDummyBetLog(
        amount: Int,
        displayName: String,
        date: Date = .init(),
        timeZone: Foundation.TimeZone = .current)
        -> TransactionDTO.Log
    {
        let dummyLog = TransactionDTO.Log(
            id: "1",
            type: .general,
            amount: "\(amount)".toAccountCurrency(),
            date: date.toLocalDateTime(timeZone),
            title: displayName,
            detailId: "",
            detailOption: .None())

        return dummyLog
    }

    func test_HasOneP2PBetLog_InTransactionLogPage_P2PLogIsDisplayedWithNumber1_KTO_TC_36() {
        stubLocalizeUtils(.Vietnam())

        let stubViewModel = mock(TransactionLogViewModelProtocol.self)

        given(stubViewModel.isPageLoading) ~> false
        given(stubViewModel.sections) ~> [
            .init(
                title: "test",
                items: [
                    self.buildDummyBetLog(
                        amount: 100,
                        displayName: Localize.string("common_p2p"))
                ])
        ]

        let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections(dummySubject)

        let expectation = sut.inspection.inspect { view in
            let sections = try view
                .view(LogSections<TransactionDTO.Log>.self)
                .vStack()
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
                .view(LogRow.self, 0)
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
                title: "test",
                items: [
                    self.buildDummyBetLog(
                        amount: 100,
                        displayName: "test")
                ])
        ]

        let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections(dummySubject)

        let expectation = sut.inspection.inspect { view in
            let sections = try view
                .view(LogSections<TransactionDTO.Log>.self)
                .vStack()
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
                .view(LogRow.self, 0)
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
                title: "test",
                items: [
                    self.buildDummyBetLog(
                        amount: -100,
                        displayName: "test")
                ])
        ]

        let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections(dummySubject)

        let expectation = sut.inspection.inspect { view in
            let sections = try view
                .view(LogSections<TransactionDTO.Log>.self)
                .vStack()
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
                .view(LogRow.self, 0)
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
        let stubPlayerConfig = PlayerConfigurationImpl(SupportLocale.China().cultureCode())
        let viewModel = TransactionLogViewModel(
            mock(AbsTransactionAppService.self),
            mock(AbsCasinoAppService.self),
            mock(AbsP2PAppService.self),
            mock(PlayerConfiguration.self),
            mock(PlayerRepository.self))

        let stubSections = viewModel
            .buildSections([
                buildDummyBetLog(
                    amount: 100,
                    displayName: "test",
                    date: .init(),
                    timeZone: stubPlayerConfig.localeTimeZone())
            ])

        let expect = Localize.string("common_today")
        let actual = stubSections.first!.title
        XCTAssertEqual(expect, actual)
    }

    func test_HasLogToday_InTransactionLogPage_LogDateIsDisplayedWithToday_KTO_TC_55() {
        let stubViewModel = mock(TransactionLogViewModelProtocol.self)

        given(stubViewModel.isPageLoading) ~> false
        given(stubViewModel.sections) ~> [
            .init(
                title: "今天",
                items: [
                    self.buildDummyBetLog(
                        amount: 100,
                        displayName: "test")
                ])
        ]

        let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections(dummySubject)

        let expectation = sut.inspection.inspect { view in
            let sectionTitle = try view
                .view(LogSections<TransactionDTO.Log>.self)
                .vStack()
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
        stubLocalizeUtils(.China())

        let stubViewModel = mock(TransactionLogViewModelProtocol.self)

        given(stubViewModel.isPageLoading) ~> false
        given(stubViewModel.sections) ~> []

        let sut = TransactionLogView<TransactionLogViewModelProtocolMock>.Sections(dummySubject)

        let expectation = sut.inspection.inspect { view in
            let description = try view
                .find(viewWithId: "emptyStateView")
                .find(viewWithId: "description")
                .localizedText()
                .string()

            XCTAssertEqual(description, "暂无纪录")
        }

        ViewHosting.host(
            view: sut
                .environmentObject(SafeAreaMonitor())
                .environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 30)
    }
  
    func test_givenPlayerHasOneRecordWithProviderLTPH_whenQueryThatRecord_thenDisplayNumberGameMyBetDetail_KTO_TC_905() {
        let stubCashAdapter = mock(CashAdapter.self).initialize(getFakeHttpClient())
    
        given(stubCashAdapter.getIncomeOutcomeAmount(begin: any(), end: any(), balanceLogFilterType: any())) ~>
            Single.just(ResponseItem(
                data: IncomeOutcomeBean(incomeAmount: "0", outcomeAmount: "0"),
                errorMsg: "",
                node: "",
                statusCode: "")).asWrapper()

        given(stubCashAdapter.getCash(
            begin: any(),
            end: any(),
            balanceLogFilterType: any(),
            page: any(),
            isDesc: any())) ~> Single.just(ResponsePayload(
            data: Payload(
                payload: [CashLogsBean(
                    date: "",
                    logs: [CashLogsBean.Log(
                        afterBalance: "0",
                        amount: "0",
                        bonusType: 0,
                        createdDate: "2023-11-02T14:05:18.2495371+07:00",
                        description: nil,
                        externalId: "",
                        shouldDisplayTransactionLogDetails: true,
                        issueNumber: 0,
                        previousBalance: "0",
                        productProvider: 18,
                        productType: 0,
                        subTitle: nil,
                        ticketType: nil,
                        transactionId: "",
                        transactionMode: nil,
                        transactionSubType: 0,
                        transactionType: 7,
                        wagerId: nil,
                        wagerType: 0,
                        isBonusLock: false)])],
                totalCount: 1),
            errorMsg: "",
            node: "",
            statusCode: ""))
            .asWrapper()

        injectFakeObject(CashProtocol.self, object: stubCashAdapter)
    
        let dummyNumberGameRecordViewModel = mock(NumberGameRecordViewModel.self)
            .initialize(numberGameRecordUseCase: mock(NumberGameRecordUseCase.self))
    
        given(dummyNumberGameRecordViewModel.getGameDetail(wagerId: any())) ~> .just(NumberGameBetDetail(
            displayId: "",
            traceId: "",
            gameName: "",
            matchMethod: "",
            betContent: [],
            betTime: try! "2023-11-02T14:05:18.2495371+07:00".toKotlinLocalDateTime(),
            stakes: FiatFactory.shared.create(supportLocale: .Vietnam(), amount: "0"),
            status: NumberGameBetDetail.BetStatusUnsettledPending(),
            resultType: .other,
            _result: ""))
    
        injectFakeObject(NumberGameRecordViewModel.self, object: dummyNumberGameRecordViewModel)
    
        let sut = TransactionLogViewController(nibName: nil, bundle: nil)
        sut.loadViewIfNeeded()
    
        let publisher = PassthroughSubject<Void, Never>()
        let contentView = (sut.children.first! as! UIHostingController<TransactionLogView<TransactionLogViewModel>>)
            .rootView
        let mockNavigationController = FakeNavigationController(rootViewController: sut)
    
        let expectation = contentView.inspection.inspect { view in
            try view
                .find(viewWithId: "section(at: 0)")
                .find(viewWithId: "row(at: 0)")
                .callOnTapGesture()
      
            publisher.send(())
        }
    
        let expectation1 = contentView.inspection.inspect(onReceive: publisher) { _ in
            let actual = mockNavigationController.lastNavigatedViewController
      
            XCTAssertTrue(actual is NumberGameMyBetDetailViewController)
        }
    
        ViewHosting.host(view: contentView)
        wait(for: [expectation, expectation1], timeout: 30)
    }
}
