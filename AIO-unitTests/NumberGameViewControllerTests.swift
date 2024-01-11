import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class NumberGameViewControllerTests: XCBaseTestCase {
  func test_givenLobbyMaintenance_thenDisplayLobbyMaintenanceInfo_KTO_TC_910() {
    let stubMaintenanceStatus = MaintenanceStatus.Product(
      productsAvailable: [.numbergame],
      status: [.numbergame: OffsetDateTime(
        localDateTime: LocalDateTime(year: 2100, month: .january, dayOfMonth: 1, hour: 12, minute: 0, second: 0, nanosecond: 0),
        timeZone: sharedbu.TimeZone.companion.of(zoneId: "Asia/Ho_Chi_Minh"))])
    
    let stubSystemStatusUseCase = mock(ISystemStatusUseCase.self)
    given(stubSystemStatusUseCase.fetchOTPStatus()) ~> .just(OtpStatus(isMailActive: true, isSmsActive: true))
    given(stubSystemStatusUseCase.fetchCustomerServiceEmail()) ~> .just("")
    given(stubSystemStatusUseCase.observeMaintenanceStatusChange()) ~> .just(())
    given(stubSystemStatusUseCase.fetchMaintenanceStatus()) ~> .just(stubMaintenanceStatus)
    given(stubSystemStatusUseCase.observeMaintenanceStatusByFetch()) ~> .just(stubMaintenanceStatus)
    
    injectFakeObject(ISystemStatusUseCase.self, object: stubSystemStatusUseCase)
    
    let dummyUseCase = mock(NumberGameUseCase.self)
    let dummyAppService = mock(AbsNumberGameAppService.self)
    
    let dummyViewModel = NumberGameViewModel(
      numberGameUseCase: dummyUseCase,
      memoryCache: mock(MemoryCacheImpl.self),
      numberGameService: dummyAppService)
    
    given(dummyUseCase.getPopularGames()) ~> .just([])
    given(dummyUseCase.getGames(order: any(), tags: any())) ~> .just([])
    given(dummyAppService.getTags()) ~> Single.just(NumberGameDTO.GameTags(newTag: nil, recommendTag: nil, gameTags: []))
      .asWrapper()
    
    injectFakeObject(NumberGameViewModel.self, object: dummyViewModel)
    
    let NumberGameVC = FakeNavigationController(rootViewController: NumberGameViewController.initFrom(storyboard: "NumberGame"))
    NumberGameVC.children.first!.loadViewIfNeeded()
    
    let actual = NumberGameVC.children.first!
    
    XCTAssertTrue(actual is ProductMaintenanceViewController)
  }
}
