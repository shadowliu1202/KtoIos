import XCTest
import Mockingbird
import ViewInspector
import SharedBu

@testable import ktobet_asia_ios_qat

extension DepositLogSummaryViewModelProtocolMock: ObservableObject { }
extension DepositLogSummaryViewModelProtocolMock: Selecting {
    
    public var dataSource: [Selectable] {
        [PaymentLogDTO.LogStatus.approved,
         PaymentLogDTO.LogStatus.reject,
         PaymentLogDTO.LogStatus.pending,
         PaymentLogDTO.LogStatus.floating]
    }
    
    public var selectedItems: [Selectable] {
        get {
            dataSource
        }
        set(newValue) {
            
        }
    }
    
    public var selectedTitle: String {
        ""
    }
}

extension DepositLogSummaryView.Sections: Inspecting { }
extension DepositLogSummaryView.Header: Inspecting { }

final class DepositLogSummaryViewTests: XCTestCase {
    
    private func generateGroupLog(date: Date = .init(), count: Int = 1) -> PaymentLogDTO.GroupLog {
        return .init(groupDate: date.toUTCOffsetDateTime().toInstant(),
                     logs: generatePaymentLogDTOLog(date: date, count: count)
        )
    }
    
    private func generateSections(date: Date = .init(), count: Int = 1) -> [DepositLogSummaryViewModelProtocol.Section] {
        return [
            .init(
                model: date.toDateString(),
                items: generatePaymentLogDTOLog(date: date, count: count)
            )
        ]
    }
    
    private func generatePaymentLogDTOLog(date: Date = .init(), count: Int = 1) -> [PaymentLogDTO.Log] {
        return (0..<count).map({
            PaymentLogDTO.Log(
                displayId: "TEST_A\($0)",
                currencyType: .fiat,
                status: PaymentStatus.floating,
                amount: "\($0 + 100)".toAccountCurrency(),
                createdDate: date.toUTCOffsetDateTime().toInstant(),
                updateDate: date.toUTCOffsetDateTime().toInstant()
            )})
    }
    
    func test_HasOneDepositLogAt20221201_InDepositLogPage_20221201LogIsDisplayedWithNumber1_KTO_TC_82() {
        let stubViewModel = mock(DepositLogSummaryViewModelProtocol.self)
        
        let date = "2022/12/01".toDate(format: "yyyy/MM/dd", timeZone: Foundation.TimeZone(abbreviation: "UTC")!)!
        given(stubViewModel.sections) ~> self.generateSections(date: date)
        
        let sut = DepositLogSummaryView<DepositLogSummaryViewModelProtocolMock>.Sections()
        
        let expectation = sut.inspection.inspect { view in
            let sections = try view
                .lazyVStack()
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
                .environmentObject(stubViewModel)
        )
        
        wait(for: [expectation], timeout: 30)
    }
    
    func test_HasDepositTotalAmount300_InDepositLogPage_DepositSummaryIsDisplayedWithNumber300_KTO_TC_83() {
        let stubViewModel = mock(DepositLogSummaryViewModelProtocol.self)
        
        given(stubViewModel.dateType) ~> .day(.init())
        given(stubViewModel.totalAmount) ~> "300"
        
        let sut = DepositLogSummaryView<DepositLogSummaryViewModelProtocolMock>.Header()
        
        let expectation = sut.inspection.inspect { view in
            let summary = try view
                .find(viewWithId: "summary")
                .hStack()
            
            XCTAssertNotNil(summary)
            
            let amount = try view
                .find(viewWithId: "summaryAmount")
                .localizedText()
                .string()
            
            XCTAssertEqual("300", amount)
        }
        
        ViewHosting.host(
            view: sut
                .environmentObject(SafeAreaMonitor())
                .environmentObject(stubViewModel)
        )
        
        wait(for: [expectation], timeout: 30)
    }
    
    
    func test_HasZeroDepositLog_InDepositLogPage_EmptyReminderIsDisplayed_KTO_TC_84() {
        injectStubCultureCode(.CN)
        
        let stubViewModel = mock(DepositLogSummaryViewModelProtocol.self)
        
        given(stubViewModel.sections) ~> []
        
        
        let sut = DepositLogSummaryView<DepositLogSummaryViewModelProtocolMock>.Sections()
        
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
                .environmentObject(stubViewModel)
        )
        
        wait(for: [expectation], timeout: 30)
    }

    func test_HasLogToday_SectionTitleIsToday_KTO_TC_85() {
        injectStubCultureCode(.CN)
        
        let stubViewModel = DepositLogSummaryViewModel(depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit())
        
        let stubSections = stubViewModel.buildSections([generateGroupLog(date: .init())])
        
        let expect = "今天"
        let actual = stubSections.first!.model
        
        XCTAssertEqual(expect, actual)
    }
}
