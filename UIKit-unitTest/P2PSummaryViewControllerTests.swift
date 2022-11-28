import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class P2PSummaryViewControllerTests: XCTestCase {
    
    override func tearDown() {
        Injection.shared.registerAllDependency()
    }

    func test_HasOneP2PGameBetRecord_InP2PSummaryPage_RecordIsDisplayedWithNumber1_KTO_TC_35() {
        let dummySummary = DateSummary(
            totalStakes: .zero(),
            totalWinLoss: .zero(),
            createdDateTime: .init(year: 2022, month: .january, dayOfMonth: 1),
            count: 1
        )
        
        let stubPlayerRepo = mock(PlayerRepository.self)
        let stubRecordRepo = mock(P2PRecordRepository.self)
        
        given(stubPlayerRepo.getUtcOffset()) ~> .just(.Companion().ZERO)
        given(stubRecordRepo.getBetSummary(zoneOffset: any())) ~> .just([dummySummary])
        
        Injectable.register(PlayerRepository.self) { _ in stubPlayerRepo }
        Injectable.register(P2PRecordRepository.self) { _ in stubRecordRepo }
        
        injectStubPlayerLoginStatus()
        
        let sut = P2PSummaryViewController.initFrom(storyboard: "P2P")
        
        sut.loadViewIfNeeded()
        sut.viewModel.fetchBetSummary()
        
        let expact = 1
        let actual = sut.tableView.numberOfRows(inSection: 0)
        
        XCTAssertEqual(expact, actual)
    }
}
