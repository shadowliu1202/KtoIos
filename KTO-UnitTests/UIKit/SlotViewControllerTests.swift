import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class SlotViewControllerTests: XCTestCase {
    
    let dummyGame = SlotGame(
        gameId: 0,
        gameName: "",
        isFavorite: false,
        gameStatus: .active,
        thumbnail: SlotThumbnail(host: "", thumbnailId: ""),
        hasForFun: false,
        jackpotPrize: 0
    )
    lazy var stubViewModel: SlotViewModel = {
        let stubSlotUseCase = mock(SlotUseCase.self)
        
        given(stubSlotUseCase.checkBonusAndCreateGame(any())) ~> .just(.inactive)
        given(stubSlotUseCase.getPopularSlots()) ~> .just([self.dummyGame])
        given(stubSlotUseCase.getNewSlots()) ~> .just([self.dummyGame])
        given(stubSlotUseCase.getJackpotSlots()) ~> .just([self.dummyGame])
        given(stubSlotUseCase.getRecentlyPlaySlots()) ~> .just([self.dummyGame])
        
        return .init(slotUseCase: stubSlotUseCase)
    }()
    
    func test_CheckBonusAndCreateGameWasCalled() {
        let sut = SlotViewController.initFrom(storyboard: "Slot")
        sut.viewModel = stubViewModel
        
        sut.loadViewIfNeeded()
        
        sut.gameDataSourceDelegate.collectionView(sut.recentlyCollectionView, didSelectItemAt: [0, 0])
        
        verify(
            sut.viewModel.checkBonusAndCreateGame(dummyGame)
        )
        .wasCalled()
    }
}
