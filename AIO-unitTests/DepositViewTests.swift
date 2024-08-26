import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

extension DepositViewModelProtocolMock: ObservableObject { }

extension DepositView.Payments: Inspecting { }
extension DepositView.Histories: Inspecting { }

final class DepositViewTests: XCBaseTestCase {
    func buildStubDepositViewModel() -> DepositViewModelProtocolMock {
        stubLocalizeUtils(.China())
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
                beneficiaries: Single<NSArray>.just([]).asWrapper()))
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
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 30)
    }

    func test_NoAvailablePayment_InDepositPage_ReminderIsDisplayed_KTO_TC_45() throws {
        let stubViewModel = buildStubDepositViewModel()

        given(stubViewModel.selections) ~> []

        let sut = DepositView<DepositViewModelProtocolMock>.Payments()

        let expectation = sut.inspection.inspect { view in
            let expect = """
            10/12日起充值通道已全面关闭，详情请您查看网站公告，感谢您的理解与配合。
            
            请您不要充值至先前的保留账户，若保留收款信息支付，您需要自行承担误存损失，感谢您的理解。
            """
      
            let actual = try view
                .find(viewWithId: "paymentsEmptyReminder")
                .localizedText()
                .string()

            XCTAssertEqual(expect, actual)
        }
    
        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 30)
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
                updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
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
            view: sut.environmentObject(stubViewModel))

        wait(for: [expectation], timeout: 30)
    }

    func test_NoDepositHistory_InDepositPage_ReminderIsDisplayedAndShowAllBtnIsNotDisplayed_KTO_TC_47() throws {
        let stubViewModel = buildStubDepositViewModel()

        given(stubViewModel.recentLogs) ~> []

        let sut = DepositView<DepositViewModelProtocolMock>.Histories()

        let reminderExpectation = sut.inspection.inspect { view in
            let expect = "目前暂无与您充值相关的纪录"
            let actual = try view
                .find(viewWithId: "historiesEmptyReminder")
                .localizedText()
                .string()

            XCTAssertEqual(expect, actual)
        }

        let showAllBtnExpectation = sut.inspection.inspect { view in
            let empty = try view
                .find(viewWithId: "historyShowAllButton")
                .modifier(VisibilityModifier.self)
                .emptyView()

            XCTAssertNotNil(empty)
        }

        ViewHosting.host(
            view: sut.environmentObject(stubViewModel))

        wait(for: [reminderExpectation, showAllBtnExpectation], timeout: 30)
    }
}
