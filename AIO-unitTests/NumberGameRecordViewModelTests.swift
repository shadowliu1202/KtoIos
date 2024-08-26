import Mockingbird
import sharedbu
import SwiftUI
import XCTest

@testable import ktobet_asia_ios

final class NumberGameRecordViewModelTests: XCTestCase {
    private func getStubRecentlyBet(count: Int) -> [RecentlyBet] {
        let fakeRecentlyBet = RecentlyBet(
            betAmount: 0,
            betId: "",
            betTypeName: "",
            gameId: 0,
            gameName: "",
            hasDetails: true,
            isStrike: true,
            matchNumber: "",
            selection: "",
            status: 1,
            wagerId: "",
            winLoss: 0
        )

        return (1 ... count).map { _ in fakeRecentlyBet }
    }

    func test_givenPlayerHasTenUnsettleRecords_whenQuery_thenHasTenRecentRecordsAndTenUnsettleRecordsAndZeroSettledRecord_KTO_TC_906(
    ) async {
        let stubNumberGameApi = mock(NumberGameApi.self).initialize(getFakeHttpClient())
        given(stubNumberGameApi.getMyBetSummary(offset: any())) ~> .just(RecordSummaryResponse(
            unsettledSummary: DateSummarynUnSettled(
                details: [
                    RecordSummary(betDate: "2023/11/05", count: 3, stakes: 0, winLoss: 0),
                    RecordSummary(betDate: "2023/11/06", count: 7, stakes: 0, winLoss: 0),
                ],
                count: 10
            ),
            settledSummary: DateSummarySettled(details: [], count: 0),
            recentlyBets: self.getStubRecentlyBet(count: 10)
        ))

        injectFakeObject(NumberGameApi.self, object: stubNumberGameApi)

        let numberGameRecordViewModel = Injectable.resolveWrapper(NumberGameRecordViewModel.self)

        let expectRecent = 10
        let actualRecent = try! await numberGameRecordViewModel.recent.values.first(where: { _ in true })!.count
        XCTAssertEqual(expectRecent, actualRecent)

        let expectUnsettle = 10
        let actualUnsettle = try! await numberGameRecordViewModel.unSettled.values
            .first(where: { _ in true })!
            .reduce(0) { partialResult, summary in partialResult + Int(summary.count) }
        XCTAssertEqual(expectUnsettle, actualUnsettle)

        let expectSettled = 0
        let actualSettled = try! await numberGameRecordViewModel.settled.values
            .first(where: { _ in true })!
            .reduce(0) { partialResult, summary in partialResult + Int(summary.count) }
        XCTAssertEqual(expectSettled, actualSettled)
    }
}
