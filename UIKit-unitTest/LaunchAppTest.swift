import XCTest
import Mockingbird
import RxSwift
import SharedBu

@testable import ktobet_asia_ios_qat

final class LaunchAppTest: XCTestCase {
    
    private lazy var stubLocalStorage = mock(LocalStorageRepository.self).initialize(nil)
    private lazy var stubAuthUseCase = mock(AuthenticationUseCase.self)
    private lazy var stubServiceStatusUseCase = mock(GetSystemStatusUseCase.self)
    
    private lazy var mockNavigator = mock(Navigator.self)
    private lazy var mockAlert = mock(AlertProtocol.self)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
        
        reset(stubLocalStorage)
        reset(stubAuthUseCase)
        reset(stubServiceStatusUseCase)
        
        reset(mockNavigator)
        reset(mockAlert)
    }
    
    func buildLaunchSUT() -> LaunchViewController? {
        let storyboard = UIStoryboard(name: "Launch", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "LaunchViewController") as? LaunchViewController
    }
    
    func buildSBKSUT() -> SportBookViewController? {
        let storyboard = UIStoryboard(name: "SBK", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SportBookViewController") as? SportBookViewController
    }
    
    func simulateApplicationWillEnterForeground() {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillEnterForeground(UIApplication.shared)
        wait(for: 2)
    }
    
    func waitAnimation() {
        wait(for: 10)
    }
    
    func test_givenUserLoggedInAndUnexpired_whenColdStart_thenEnterLobbyPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> .init(account: "", ID: "", locale: "", VIPLevel: 1, defaultProduct: 1)
        
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false
                
        NavigationManagement.sharedInstance = mockNavigator
        
        let sut = buildLaunchSUT()
        
        sut?.viewModel.authUseCase = stubAuthUseCase
        sut?.viewModel.localStorageRepo = stubLocalStorage
        
        sut?.loadViewIfNeeded()
        
        sut?.executeNavigation()

        verify(
            mockNavigator.goTo(
                productType: .sbk,
                isMaintenance: any()
            )
        )
        .wasCalled()
    }
    
    func test_givenUserLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> .init(account: "", ID: "", locale: "", VIPLevel: 1, defaultProduct: 1)
        
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true
                
        NavigationManagement.sharedInstance = mockNavigator
        
        let sut = buildLaunchSUT()
        
        sut?.viewModel.authUseCase = stubAuthUseCase
        sut?.viewModel.localStorageRepo = stubLocalStorage
        
        sut?.loadViewIfNeeded()
        
        sut?.executeNavigation()

        waitAnimation()
        
        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
    }
    
    func test_givenUserNotLoggedInAndUnexpired_whenColdStart_thenEnterLandingPage() {
    }
    
    func test_givenUserNotLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
    }
    
    func test_givenUserOpenAppFirstTime_whenColdStart_thenEnterLandingPage() {
    }
    
    func test_givenUserLoggedInAndUnexpired_whenHotStart_thenBackToOriginalPage() {
        given(stubAuthUseCase.isLogged()) ~> .just(true)
        
        Injectable
            .register(AuthenticationUseCase.self) { [unowned self] _ in
                self.stubAuthUseCase
            }
        
        NavigationManagement.sharedInstance = mockNavigator
        
        simulateApplicationWillEnterForeground()
        
        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasNeverCalled()
    }
    
    func test_givenUserLoggedInAndExpired_whenHotStart_thenEnterLandingPage() {
        given(stubAuthUseCase.isLogged()) ~> .just(false)
        
        Injectable
            .register(AuthenticationUseCase.self) { [unowned self] _ in
                self.stubAuthUseCase
            }
        
        NavigationManagement.sharedInstance = mockNavigator
        
        simulateApplicationWillEnterForeground()
        
        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
    }
    
    func test_givenUserNotLoggedInAndUnexpired_whenHotStart_thenEnterLandingPage() {  }
    
    func test_givenUserNotLoggedInAndExpired_whenHotStart_thenEnterLandingPage() { }
    
    func test_givenOpenApp_whenUnderMaintenance_thenEnterMaintenancePage() {
        given(stubServiceStatusUseCase.observePortalMaintenanceState()) ~> .just(.AllPortal(duration: 1000))
        given(stubServiceStatusUseCase.getOtpStatus()) ~> .just(.init(isMailActive: false, isSmsActive: false))
        given(stubServiceStatusUseCase.getCustomerServiceEmail()) ~> .just("")
        given(stubServiceStatusUseCase.getYearOfCopyRight()) ~> .just("")
        
        given(stubLocalStorage.getPlayerInfo()) ~> .init(account: "", ID: "", locale: "", VIPLevel: 1, defaultProduct: 1)
        
        given(stubAuthUseCase.logout()) ~> Single<Void>.just(()).asCompletable
        
        Alert.shared = mockAlert
        
        let sut = buildSBKSUT()
        
        sut?.serviceViewModel = .init(
            systemStatusUseCase: stubServiceStatusUseCase,
            localStorageRepo: stubLocalStorage
        )
        
        sut?.playerViewModel = .init(
            playerUseCase: Injectable.resolveWrapper(PlayerDataUseCase.self),
            authUseCase: stubAuthUseCase
        )
        
        sut?.loadViewIfNeeded()
        
        verify(
            mockAlert.show(
                Localize.string("common_urgent_maintenance"),
                Localize.string("common_maintenance_logout"),
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()
            )
        )
        .wasCalled()
    }
}
