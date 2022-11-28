import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class TransactionLogViewControllerTests: XCTestCase {
    
    override func tearDown() {
        Injection.shared.registerAllDependency()
    }
    
    private func buildDummyP2PBetLog() -> GeneralProduct {
        let dummyDetail = BalanceLogDetail(
            afterBalance: .zero(),
            amount: .zero(),
            date: Date().convertToKotlinx_datetimeLocalDateTime(),
            wagerMappingId: "",
            productGroup: .P2P(supportProvider: .CompanionNone()),
            productType: .p2p,
            transactionType: .ProductBet(),
            remark: .None(),
            externalId: ""
        )
        
        let dummyLog = GeneralProduct(
            transactionLog: dummyDetail,
            displayName: .init(title: Localize.convert(resourceId: .init(key: "common_p2p")))
        )
        
        return dummyLog
    }
    
    func test_HasOneP2PBetRecrod_InTransactionLogPage_P2PLogIsDisplayedWithNumber1_KTO_TC_36() {
        injectStubCultureCode(.VN)
        
        let stubTransactionRepo = mock(TransactionLogRepository.self)
        
        given(stubTransactionRepo.searchTransactionLog(
            from: any(),
            to: any(),
            BalanceLogFilterType: any(),
            page: any())
        ) ~> .just([self.buildDummyP2PBetLog()])
        
        given(stubTransactionRepo.getCashFlowSummary(
            begin: any(),
            end: any(),
            balanceLogFilterType: any())
        ) ~> .just(.init(income: .zero(), outcome: .zero()))
                        
        Injectable.register(TransactionLogRepository.self) { _ in stubTransactionRepo }
        
        injectStubPlayerLoginStatus()
        
        let sut = TransactionLogViewController.initFrom(storyboard: "TransactionLog")
        
        sut.loadViewIfNeeded()
        
        let expactCount = 1
        let actualCount = sut.tableView.numberOfRows(inSection: 0)
        
        XCTAssertEqual(expactCount, actualCount)
        
        let cell = sut.tableView.cellForRow(at: [0, 0]) as! TransactionLogTableViewCell
        let expactName = "Đánh Bài Đối Kháng"
        let actualName = cell.nameLabel.text!
        
        XCTAssertEqual(expactName, actualName)
    }
}


