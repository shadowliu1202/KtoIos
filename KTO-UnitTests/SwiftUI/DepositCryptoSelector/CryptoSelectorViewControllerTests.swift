import Mockingbird
import SharedBu
import XCTest
import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

extension CryptoDepositViewModelProtocolMock: ObservableObject { }

final class CryptoSelectorViewControllerTests: XCTestCase {

  override func tearDown() {
      Injection.shared.registerAllDependency()
  }
  
  func test_TapVideoTutorialBtn_InCryptoSelectorPage_VideoTutorialIsDisplayed_KTO_TC_40() {
    let sut = CryptoSelectorViewController.instantiate()

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
    
    let sut = CryptoSelectorViewController.instantiate(localStorageRepo: stubLocalRepo)
    
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
    
    let sut = CryptoSelectorViewController.instantiate(localStorageRepo: stubLocalRepo)
    
    makeItVisible(sut)
    
    sut.loadViewIfNeeded()
    
    sut.navigateToGuide()
    
    let expact = "\(CryptoGuideVNDViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
  
  func test_TapSubmitBtn_InCryptoSelectorPage_DepositCryptoViewIsDisplayed() {
    let sut = CryptoSelectorViewController.instantiate()

    makeItVisible(sut)

    sut.loadViewIfNeeded()

    sut.navigateToDepositCryptoVC("")

    let expact = "\(DepositCryptoViewController.self)"
    let actual = "\(type(of: sut.presentedViewController!))"

    XCTAssertEqual(expact, actual)
  }
  
  func test_givenDepositCountOverLimit_InCryptoSelectPage_thenAlertRequestLater() {
    injectStubCultureCode(.CN)

    let error = NSError(domain: "", code: 0, userInfo: ["statusCode": "10101", "errorMsg": ""])
    let playerDepositCountOverLimit = ExceptionFactory.create(error)

    let stubViewModel = mock(CryptoDepositViewModel.self)
      .initialize(depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
                  navigator: mock(DepositNavigator.self))

    given(stubViewModel.errors()) ~> .just(playerDepositCountOverLimit)

    let stubAlert = mock(AlertProtocol.self)
    Alert.shared = stubAlert

    let sut = CryptoSelectorViewController.instantiate(viewModel: stubViewModel)
  
    sut.loadViewIfNeeded()

    stubViewModel.errorsSubject.onNext(error)

    verify(
      stubAlert.show(
        any(),
        "您有五个待处理的充值请求，请您过三分钟后再试",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }
}
