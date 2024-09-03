import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

final class FavoriteViewControllerTests: XCTestCase {
    func test_givenFavoriteGameIsMaintain_thenDisplayFavoriteGameInMaintenance_KTO_TC_911() {
        let stubNumberGameApi = mock(NumberGameApi.self).initialize(getFakeHttpClient())
        given(stubNumberGameApi.getFavorite()) ~> .just([NumberGameEntity(
            gameId: 0,
            gameName: "",
            isFavorite: true,
            gameStatus: 1,
            imageId: "",
            cultureCode: "vi-vn",
            hasForFun: false,
            isMaintenance: true
        )])

        injectFakeObject(NumberGameApi.self, object: stubNumberGameApi)

        let favoriteVC = FavoriteViewController.initFrom(storyboard: "Product")
        favoriteVC.viewModel = Injectable.resolveWrapper(NumberGameViewModel.self)

        makeItVisible(favoriteVC)
        favoriteVC.loadViewIfNeeded()

        let cell = favoriteVC.gamesCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! WebGameItemCell

        let expect = false
        let actual = cell.blurView.isHidden

        XCTAssertEqual(expect, actual)
    }
}
