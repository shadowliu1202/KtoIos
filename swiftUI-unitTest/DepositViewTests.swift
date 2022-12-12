import XCTest
import SwiftUI
import ViewInspector
import SharedBu
import Mockingbird

@testable import ktobet_asia_ios_qat

extension DepositViewModelProtocolMock: ObservableObject { }

extension DepositView.Payments: Inspecting { }
extension DepositView.PaymentHeader: Inspectable { }
extension DepositView.Histories: Inspecting { }
extension DepositView.HistoryHeader: Inspectable { }

final class DepositViewTests: XCTestCase {
    
    func buildStubDepositViewModel() -> DepositViewModelProtocolMock {
        injectStubCultureCode(.CN)
        return mock(DepositViewModelProtocol.self)
    }
    
    func test_HasOnePayment_InDepositPage_OnePaymentIsDisplayed_KTO_TC_44() throws {
        let stubViewModel = buildStubDepositViewModel()

        given(stubViewModel.selections) ~> [
            OnlinePayment(.init(
                identity: "1",
                name: "Test",
                hint: "This is test",
                isRecommend: false,
                beneficiaries: Single<NSArray>.just([]).asWrapper()
            ))
        ]
        
        let sut = DepositView<DepositViewModelProtocolMock>.Payments()
        
        let expectation = sut.inspection.inspect { view in
            let numberOfRows = try view
                .find(viewWithId: "payments")
                .forEach()
                .count
            
            XCTAssertEqual(numberOfRows, 1)
        }
        
        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_NoAvailablePayment_InDepositPage_ReminderIsDisplayed_KTO_TC_45() throws {
        let stubViewModel = buildStubDepositViewModel()
                
        given(stubViewModel.selections) ~> []
        
        let sut = DepositView<DepositViewModelProtocolMock>.Payments()
        
        let expectation = sut.inspection.inspect { view in
            let expect = "目前暂无可用的充值方式"
            let actual = try view
                .find(viewWithId: "paymentsEmptyReminder")
                .findText()
                .string()
            
            XCTAssertEqual(expect, actual)
        }
        
        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_HasOneDepositHistory_InDepositPage_OneHistoryIsDisplayed_KTO_TC_46() throws {
        let stubViewModel = buildStubDepositViewModel()

        given(stubViewModel.recentLogs) ~> [
            PaymentLogDTO.Log(
                displayId: "TEST",
                currencyType: .fiat,
                status: .approved,
                amount: "100".toAccountCurrency(),
                createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0)
            )
        ]

        let sut = DepositView<DepositViewModelProtocolMock>.Histories()

        let expectation = sut.inspection.inspect { view in
            let numberOfRows = try view
                .find(viewWithId: "histories")
                .forEach()
                .count
            
            XCTAssertEqual(numberOfRows, 1)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [expectation], timeout: 10)
    }
    
    func test_NoDepositHistory_InDepositPage_ReminderIsDisplayedAndShowAllBtnIsNotDisplayed_KTO_TC_47() throws {
        let stubViewModel = buildStubDepositViewModel()

        given(stubViewModel.recentLogs) ~> []

        let sut = DepositView<DepositViewModelProtocolMock>.Histories()

        let reminderExpectation = sut.inspection.inspect { view in
            let expect = "目前暂无与您充值相关的纪录"
            let actual = try view
                .find(viewWithId: "historiesEmptyReminder")
                .findText()
                .string()
            
            XCTAssertEqual(expect, actual)
        }
        
        let showAllBtnExpectation = sut.inspection.inspect { view in
            let empty = try view
                .find(viewWithId: "historyShowAllButton")
                .emptyView()
            
            XCTAssertNotNil(empty)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel)
        )

        wait(for: [reminderExpectation, showAllBtnExpectation], timeout: 10)
    }
}

