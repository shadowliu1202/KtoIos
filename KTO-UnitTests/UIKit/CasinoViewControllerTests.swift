import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class CasinoViewControllerTests: XCTestCase {

    let dummyTurnoverDetail: TurnOverDetail = .init(
        achieved: "".toAccountCurrency(),
        formula: "",
        informPlayerDate: Date().toUTCOffsetDateTime(),
        name: "Test bonus",
        bonusId: "",
        remainAmount: "9527".toAccountCurrency(),
        parameters: .init(
            amount: "100.00".toAccountCurrency(),
            balance: "".toAccountCurrency(),
            betMultiplier: 0,
            capital: "".toAccountCurrency(),
            depositRequest: "".toAccountCurrency(),
            percentage: .init(percent: 87.87),
            request: "".toAccountCurrency(),
            requirement: "".toAccountCurrency(),
            turnoverRequest: "95270".toAccountCurrency()
        )
    )
    
    func stubCasinoUseCase(
        requireNoBonusLock: Bool,
        result: WebGameResult
    ) -> CasinoUseCase {
        let stubCasinoUseCase = mock(CasinoUseCase.self)
        
        given(stubCasinoUseCase.getLobbies()) ~> .just([])
        given(stubCasinoUseCase.checkBonusAndCreateGame(any())) ~> .just(result)
        given(stubCasinoUseCase.searchGamesByTag(tags: any())) ~> .just([
            CasinoGame(
                gameId: 0,
                gameName: "",
                isFavorite: false,
                gameStatus: .active,
                thumbnail: CasinoThumbnail(host: "", thumbnailId: ""),
                requireNoBonusLock: requireNoBonusLock,
                releaseDate: .init(year: 2022, month: .december, dayOfMonth: 12)
            )
        ])
        
        return stubCasinoUseCase
    }
    
    func stubViewModel(
        requireNoBonusLock: Bool,
        result: WebGameResult
    ) -> CasinoViewModel {
        
        let viewModel = CasinoViewModel(
            casinoRecordUseCase: mock(CasinoRecordUseCase.self),
            casinoUseCase: stubCasinoUseCase(requireNoBonusLock: requireNoBonusLock, result: result),
            memoryCache: mock(MemoryCacheImpl.self),
            casinoAppService: Injectable.resolveWrapper(ApplicationFactory.self).casino()
        )
        
        viewModel.tagStates = .just([])
        
        return viewModel
    }
    
    func test_UserHaveBonusLockAndNotCalculating_PressRequireNoBonusLockGame_ShowBonusLockDetailAlert_KTO_TC_95() {
        let stubViewModel = stubViewModel(
            requireNoBonusLock: true,
            result: .lockedBonus(gameName: "", dummyTurnoverDetail)
        )
        
        let sut = CasinoViewController.initFrom(storyboard: "Casino")
        sut.viewModel = stubViewModel
        
        makeItVisible(sut)
        
        sut.gameDataSourceDelegate.collectionView(sut.gamesCollectionView, didSelectItemAt: [0, 0])
    
        let presented = "\(type(of: sut.presentedViewController!))"
        XCTAssertEqual(presented, "TurnoverAlertViewController")
    }
    
    func test_UserHaveBonusLockAndCalculating_PressRequireNoBonusLockGame_ShowBonusCalculatingAlert_KTO_TC_96() {
        injectStubCultureCode(.CN)
        
        let stubViewModel = stubViewModel(
            requireNoBonusLock: true,
            result: .bonusCalculating(gameName: "TestGame")
        )
        
        let stubAlert = mock(AlertProtocol.self)
        Alert.shared = stubAlert
        
        let sut = CasinoViewController.initFrom(storyboard: "Casino")
        sut.viewModel = stubViewModel
        
        sut.loadViewIfNeeded()
                
        sut.gameDataSourceDelegate.collectionView(sut.gamesCollectionView, didSelectItemAt: [0, 0])
    
        verify(
            stubAlert.show(
                "温馨提示",
                any(String.self, where: {
                    $0.contains("TestGame")
                }),
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()
            )
        )
        .wasCalled()
    }
    
    func test_UserNoBonusLock_PressNotRequireNoBonusLockGame_EnterGamePage_KTO_TC_97() {
        let stubViewModel = stubViewModel(
            requireNoBonusLock: false,
            result: .loaded(gameName: "", nil)
        )
        
        let sut = CasinoViewController.initFrom(storyboard: "Casino")
        sut.viewModel = stubViewModel
        
        makeItVisible(sut)
        
        sut.gameDataSourceDelegate.collectionView(sut.gamesCollectionView, didSelectItemAt: [0, 0])
    
        let presentedNavigation = sut.presentedViewController as! UINavigationController
        let presentedPage = "\(type(of: presentedNavigation.viewControllers.first!))"
        XCTAssertEqual(presentedPage, "GameWebViewViewController")
    }
}
