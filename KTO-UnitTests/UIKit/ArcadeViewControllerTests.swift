import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class ArcadeViewControllerTests: XCBaseTestCase {
  let dummyGame = ArcadeGame(
    gameId: 0,
    gameName: "Test Arcade",
    isFavorite: false,
    gameStatus: .active,
    thumbnail: ArcadeThumbnail(host: "", thumbnailId: ""),
    requireNoBonusLock: true)

  func stubViewModel() -> ArcadeViewModel {
    let stubUseCase = mock(ArcadeUseCase.self)
    given(stubUseCase.getGames(isRecommend: any(), isNew: any())) ~> .just([self.dummyGame])
    given(stubUseCase.checkBonusAndCreateGame(any())) ~> .just(.loaded(gameName: "Test Arcade", nil))

    let memoryCache = mock(MemoryCacheImpl.self)

    let arcadeService = mock(AbsArcadeAppService.self)
    let tags: ArcadeDTO.GameTags = .init(newTag: nil, recommendTag: nil)
    given(arcadeService.getTags()) ~> Single.just(tags).asWrapper()

    return ArcadeViewModel(
      arcadeUseCase: stubUseCase,
      memoryCache: memoryCache,
      arcadeAppService: arcadeService)
  }

  func testCheckBonusAndCreateGameWasCalled() {
    let stubViewModel = stubViewModel()

    let sut = ArcadeViewController.initFrom(storyboard: "Arcade")
    sut.viewModel = stubViewModel

    makeItVisible(sut)

    sut.gameDataSourceDelegate.collectionView(sut.gamesCollectionView, didSelectItemAt: [0, 0])

    verify(
      stubViewModel.checkBonusAndCreateGame(dummyGame))
      .wasCalled()
  }
}
