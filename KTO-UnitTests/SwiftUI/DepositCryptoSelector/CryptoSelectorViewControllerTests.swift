import Mockingbird
import SharedBu
import XCTest
import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

extension CryptoDepositViewModelProtocolMock: ObservableObject { }

final class CryptoSelectorViewControllerTests: XCTestCase {

  func test_TapVideoTutorialBtn_InCryptoSelectorPage_VideoTutorialIsDisplayed_KTO_TC_40() {
    let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")

    makeItVisible(sut)

    sut.loadViewIfNeeded()

    sut.navigateToVideoTutorial()

    let expact = "\(CryptoVideoTutorialViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
  
  func test_AtCNEnvironmentTapCryptoGuideText_InCryptoSelectorPage_CNCryptoGuideIsDisplayed_KTO_TC_1() {
    let stubLocalRepo = mock(LocalStorageRepository.self)
    given(stubLocalRepo.getSupportLocale()) ~> .China()
    
    let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")
    sut.localStorageRepo = stubLocalRepo
    
    makeItVisible(sut)
    
    sut.loadViewIfNeeded()
    
    sut.navigateToGuide()
    
    let expact = "\(CryptoGuideViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
  
  func test_AtVNEnvironmentTapCryptoGuideText_InCryptoSelectorPage_VNCryptoGuideIsDisplayed_KTO_TC_2() {
    let stubLocalRepo = mock(LocalStorageRepository.self)
    given(stubLocalRepo.getSupportLocale()) ~> .Vietnam()
    
    let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")
    sut.localStorageRepo = stubLocalRepo
    
    makeItVisible(sut)
    
    sut.loadViewIfNeeded()
    
    sut.navigateToGuide()
    
    let expact = "\(CryptoGuideVNDViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
  
  func test_TapSubmitBtn_InCryptoSelectorPage_DepositCryptoViewIsDisplayed() {
    let sut = CryptoSelectorViewController.initFrom(storyboard: "Deposit")

    makeItVisible(sut)

    sut.loadViewIfNeeded()

    sut.navigateToDepositCryptoVC("")

    let expact = "\(DepositCryptoViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
}
