import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension CasinoBetDetailView.Cell: Inspecting { }
extension CasinoBetDetailView.RoundIDCell: Inspecting { }

extension ICasinoBetDetailViewModelMock: ObservableObject { }

final class CasinoBetDetailViewTests: XCBaseTestCase {
    private let fakeViewModel = mock(ICasinoBetDetailViewModel.self)
  
    private func getStubBetDetail(roundID: String?) -> CasinoDTO.BetDetail {
        .init(
            id: "",
            otherId: "",
            roundId: roundID,
            betTime: stubInstant(),
            selection: "",
            gameName: "TestGameName",
            gameResult: .init(
                displayType: .none,
                cards: nil,
                dices: nil,
                roulette: nil,
                chineseDice: nil,
                fanTan: nil,
                colorPlates: nil),
            stakes: stubFiatCNY("0"),
            prededuct: stubFiatCNY("0"),
            winLose: .init(status: .win, amount: stubFiatCNY("50")),
            status: .settled)
    }
  
    func test_givenBetDetailHasRoundID_thenDisplayGameNameAndRoundID_KTO_TC_194() {
        let stubBetDetail = getStubBetDetail(roundID: "testRoundID")
    
        let sut = CasinoBetDetailView<ICasinoBetDetailViewModelMock>.RoundIDCell(stubBetDetail)
        let exp = sut.inspection.inspect { view in
            let roundIDCell = try view.find(viewWithId: "roundIDCell")
            let ActualTitle = try roundIDCell.find(viewWithId: "title").localizedText().string()
            let ActualContent = try roundIDCell.find(viewWithId: "content").localizedText().string()
      
            let expectTitle = Localize.string("product_game_name_id")
            let expectContent = "TestGameName(testRoundID)"
      
            XCTAssertEqual(expectTitle, ActualTitle)
            XCTAssertEqual(expectContent, ActualContent)
        }
    
        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }

    func test_givenBetDetailHasNoRoundID_thenDisplayGameName_KTO_TC_195() {
        let stubBetDetail = getStubBetDetail(roundID: nil)
    
        let sut = CasinoBetDetailView<ICasinoBetDetailViewModelMock>.RoundIDCell(stubBetDetail)
        let exp = sut.inspection.inspect { view in
            let roundIDCell = try view.find(viewWithId: "roundIDCell")
            let ActualTitle = try roundIDCell.find(viewWithId: "title").localizedText().string()
            let ActualContent = try roundIDCell.find(viewWithId: "content").localizedText().string()
      
            let expectTitle = Localize.string("product_game_name")
            let expectContent = "TestGameName"
      
            XCTAssertEqual(expectTitle, ActualTitle)
            XCTAssertEqual(expectContent, ActualContent)
        }
    
        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
}
