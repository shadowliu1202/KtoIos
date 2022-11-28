import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class CryptoSelectorViewControllerTests: XCTestCase {
    
    func test_TapVideoTutorialBtn_InCryptoSelectorPage_VideoTutorialIsDisplayed_KTO_TC_40() {
        let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")

        makeItVisible(sut)
        
        sut.loadViewIfNeeded()
        
        sut.videoTutorialBtn.sendActions(for: .touchUpInside)
        
        let expact = "\(CryptoVideoTutorialViewController.self)"
        let actual = "\(type(of: sut.presentedViewController!))"
        
        XCTAssertEqual(expact, actual)
    }
    
    func test_AtVNEnviroment_InCryptoSelectorPage_VideoTutorialBtnIsDisplayed_KTO_TC_41() {
        let stubLocalRepo = mock(LocalStorageRepository.self)

        given(stubLocalRepo.getCultureCode()) ~> Language.VN.rawValue
        given(stubLocalRepo.getSupportLocale()) ~> .Vietnam()

        Injectable.register(LocalStorageRepository.self) { _ in stubLocalRepo }
        
        let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")
        
        sut.loadViewIfNeeded()

        let actual = sut.videoTutorialBtn.isHidden

        XCTAssertFalse(actual)
    }
    
    func test_AtCNEnvironment_InCryptoSelectorPage_VideoTutorialBtnIsNotDisplayed_KTO_TC_42() {
        let stubLocalRepo = mock(LocalStorageRepository.self)

        given(stubLocalRepo.getCultureCode()) ~> Language.CN.rawValue
        given(stubLocalRepo.getSupportLocale()) ~> .China()

        Injectable.register(LocalStorageRepository.self) { _ in stubLocalRepo }
        
        let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")
        
        sut.loadViewIfNeeded()

        let actual = sut.videoTutorialBtn.isHidden

        XCTAssertTrue(actual)
    }
}
