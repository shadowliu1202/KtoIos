import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class P2PViewControllerTests: XCBaseTestCase {
    func test_HasOneP2PGame_InP2PPage_GameIsDisplayedWithNumber1_KTO_TC_34() {
        let dummyGame = P2PGame(
            gameId: 1,
            gameName: "",
            isFavorite: false,
            gameStatus: .active,
            thumbnail: P2PThumbnail(host: "", thumbnailId: ""))

        let stubRepo = mock(P2PRepository.self)

        given(stubRepo.getAllGames()) ~> .just([dummyGame])

        Injectable.register(P2PRepository.self) { _ in stubRepo }

        let sut = P2PViewController.initFrom(storyboard: "P2P")

        sut.loadViewIfNeeded()
        sut.viewModel.refreshTrigger.onNext(())

        let expact = 1
        let actual = sut.tableView.numberOfRows(inSection: 0)

        XCTAssertEqual(expact, actual)
    }
}
