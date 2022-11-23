import XCTest
import Mockingbird
import RxSwift
import SharedBu

@testable import ktobet_asia_ios_qat

final class LaunchAppTest: XCTestCase {
    
    private let loggedPlayer = PlayerInfoCache(
        account: "",
        ID: "",
        locale: "",
        VIPLevel: 1,
        defaultProduct: 1
    )
    
    private lazy var stubLocalStorage = mock(LocalStorageRepository.self)
    private lazy var stubAuthUseCase = mock(AuthenticationUseCase.self)
    private lazy var stubServiceStatusUseCase = mock(GetSystemStatusUseCase.self)
    
    private lazy var mockNavigator = mock(Navigator.self)
    private lazy var mockAlert = mock(AlertProtocol.self)
        
    override func tearDown() {
        super.tearDown()
        
        reset(stubLocalStorage)
        reset(stubAuthUseCase)
        reset(stubServiceStatusUseCase)
        
        reset(mockNavigator)
        reset(mockAlert)
    }
    
    func simulateApplicationWillEnterForeground() {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillEnterForeground(UIApplication.shared)
    }
    
    func simulateAnimationEnd() {
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func makeLaunchSUT() -> LaunchViewController {
        .initFrom(storyboard: "Launch")
    }
    
    func makeSBKSUT() -> SportBookViewController {
        .initFrom(storyboard: "SBK")
    }
    
    func test_givenUserLoggedInAndUnexpired_whenColdStart_thenEnterLobbyPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> self.loggedPlayer

        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel.authUseCase = self.stubAuthUseCase
        sut.viewModel.localStorageRepo = self.stubLocalStorage
        
        sut.loadViewIfNeeded()
        sut.executeNavigation()

        verify(
            mockNavigator.goTo(
                productType: .sbk,
                isMaintenance: any()
            )
        )
        .wasCalled()
    }
    
    func test_givenUserLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> self.loggedPlayer
        
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true
                
        NavigationManagement.sharedInstance = mockNavigator
        
        let sut = makeLaunchSUT()
        sut.viewModel.authUseCase = self.stubAuthUseCase
        sut.viewModel.localStorageRepo = self.stubLocalStorage
        
        sut.loadViewIfNeeded()
        sut.executeNavigation()
        
        simulateAnimationEnd()
        
        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
    }
    
    func test_givenUserNotLoggedInAndUnexpired_whenColdStart_thenEnterLandingPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> nil
        
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false
                
        NavigationManagement.sharedInstance = mockNavigator
        
        let sut = makeLaunchSUT()
        sut.viewModel.authUseCase = self.stubAuthUseCase
        sut.viewModel.localStorageRepo = self.stubLocalStorage
        
        sut.loadViewIfNeeded()
        sut.executeNavigation()
        
        simulateAnimationEnd()
        
        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
    }
    
    func test_givenUserNotLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> nil

        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel.authUseCase = self.stubAuthUseCase
        sut.viewModel.localStorageRepo = self.stubLocalStorage
        
        sut.loadViewIfNeeded()
        sut.executeNavigation()
        
        simulateAnimationEnd()

        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
    }

    func test_givenUserOpenAppFirstTime_whenColdStart_thenEnterLandingPage() {
        given(stubLocalStorage.getPlayerInfo()) ~> nil

        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel.authUseCase = self.stubAuthUseCase
        sut.viewModel.localStorageRepo = self.stubLocalStorage
        
        sut.loadViewIfNeeded()
        sut.executeNavigation()
        
        simulateAnimationEnd()

        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"
            )
        )
        .wasCalled()
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

    func test_givenUserNotLoggedInAndUnexpired_whenHotStart_thenEnterLandingPage() {
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

    func test_givenUserNotLoggedInAndExpired_whenHotStart_thenEnterLandingPage() {
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

    func test_givenOpenApp_whenUnderMaintenance_thenEnterMaintenancePage() {
        given(stubServiceStatusUseCase.observePortalMaintenanceState()) ~> .just(.AllPortal(duration: 1000))
        given(stubServiceStatusUseCase.getOtpStatus()) ~> .just(.init(isMailActive: false, isSmsActive: false))
        given(stubServiceStatusUseCase.getCustomerServiceEmail()) ~> .just("")
        given(stubServiceStatusUseCase.getYearOfCopyRight()) ~> .just("")

        given(stubLocalStorage.getPlayerInfo()) ~> .init(account: "", ID: "", locale: "", VIPLevel: 1, defaultProduct: 1)

        given(stubAuthUseCase.logout()) ~> Single<Void>.just(()).asCompletable

        Alert.shared = mockAlert

        let sut = makeSBKSUT()
        
        sut.serviceViewModel = .init(
            systemStatusUseCase: self.stubServiceStatusUseCase,
            localStorageRepo: self.stubLocalStorage
        )

        sut.playerViewModel = .init(
            playerUseCase: Injectable.resolveWrapper(PlayerDataUseCase.self),
            authUseCase: self.stubAuthUseCase
        )

        sut.loadViewIfNeeded()

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

