import Mockingbird
import RxSwift
import RxTest
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

@MainActor
final class MaintenanceViewModelTests: XCTestCase {
  func test_givenAllMaintenance_whenPullStatus_thenGetAllMaintenanceAndReceiveAllMaintenance() async {
    let stubSystemStatusUseCase = mock(ISystemStatusUseCase.self)
    let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)
    
    given(stubSystemStatusUseCase.fetchMaintenanceStatus()) ~> .just(.AllPortal(duration: nil))
    given(stubSystemStatusUseCase.observeMaintenanceStatusChange()) ~> .never()
    
    let sut = MaintenanceViewModel(stubSystemStatusUseCase, dummyAuthenticationUseCase)
    
    let receiveResult = TestScheduler(initialClock: 0).createObserver(MaintenanceStatus.AllPortal.self)
    _ = sut.portalMaintenanceStatus.asObservable().subscribe(receiveResult)
    
    let pullResult = await sut.pullMaintenanceStatus()
    
    XCTAssertRecordedElements(receiveResult.events, [.AllPortal(duration: nil)])
    XCTAssertEqual(pullResult, .AllPortal(duration: nil))
  }
  
  func test_whenPullStatusOnError_thenGetAllMaintenanceAndReceiveAllMaintenance() async {
    let stubSystemStatusUseCase = mock(ISystemStatusUseCase.self)
    let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)
    
    given(stubSystemStatusUseCase.fetchMaintenanceStatus()) ~> .error(KTOError.EmptyData)
    given(stubSystemStatusUseCase.observeMaintenanceStatusChange()) ~> .never()
    
    let sut = MaintenanceViewModel(stubSystemStatusUseCase, dummyAuthenticationUseCase)
    
    let receiveResult = TestScheduler(initialClock: 0).createObserver(MaintenanceStatus.AllPortal.self)
    _ = sut.portalMaintenanceStatus.asObservable().subscribe(receiveResult)
    
    let pullResult = await sut.pullMaintenanceStatus()
    
    XCTAssertRecordedElements(receiveResult.events, [.AllPortal(duration: nil)])
    XCTAssertEqual(pullResult, .AllPortal(duration: nil))
  }
}
