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
        defaultProduct: 3
    )
    
    private lazy var mockNavigator = mock(Navigator.self)
        
    override func tearDown() {
        super.tearDown()
        reset(mockNavigator)
        Injection.shared.registerAllDependency()
    }
    
    private func simulateApplicationWillEnterForeground() {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillEnterForeground(UIApplication.shared)
    }
    
    private func simulateAnimationEnd() {
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    private func makeLaunchSUT() -> LaunchViewController {
        .initFrom(storyboard: "Launch")
    }
    
    private func getFakeNavigationViewModel(
        stubAuthenticationUseCase: AuthenticationUseCaseMock = mock(AuthenticationUseCase.self),
        stubPlayerDataUseCase: PlayerDataUseCaseMock = mock(PlayerDataUseCase.self),
        stubLocalizationPolicyUseCase: LocalizationPolicyUseCaseMock = mock(LocalizationPolicyUseCase.self),
        stubGetSystemStatusUseCase: GetSystemStatusUseCaseMock = mock(GetSystemStatusUseCase.self),
        stubLocalStorageRepository: LocalStorageRepositoryMock = mock(LocalStorageRepository.self)
    ) -> NavigationViewModel
    {
        NavigationViewModel(
            stubAuthenticationUseCase,
            stubPlayerDataUseCase,
            stubLocalizationPolicyUseCase,
            stubGetSystemStatusUseCase,
            stubLocalStorageRepository
        )
    }
    
    private func stubLoginStatus(isLogged: Bool) {
        let stubNavigationViewModel = getFakeNavigationViewModelMock()
        given(stubNavigationViewModel.checkIsLogged()) ~> .just(isLogged)
        
        let stubPlayerViewModel = getFakePlayerViewModelMock()
        given(stubPlayerViewModel.checkIsLogged()) ~> .just(isLogged)
        given(stubPlayerViewModel.logout()) ~> Single<Void>.just(()).asCompletable
        
        Injectable.register(NavigationViewModel.self) { _ in
            stubNavigationViewModel
        }
        
        Injectable.register(PlayerViewModel.self) { _ in
            stubPlayerViewModel
        }
    }
    
    private func stubMaintenanceStatus(isAllMaintenance: Bool) {
        let stubServiceStatusViewModel = getFakeServiceStatusViewModelMock()
        given(stubServiceStatusViewModel.output)
        ~> .init(
            portalMaintenanceStatus: isAllMaintenance ? .just(.AllPortal(duration: 1000)) : .never(),
            portalMaintenanceStatusPerSecond: .never(),
            otpService: .never(),
            customerServiceEmail: .never(),
            productMaintainTime: .never(),
            productsMaintainTime: .never()
        )
        
        Injectable.register(ServiceStatusViewModel.self) { _ in
            stubServiceStatusViewModel
        }
    }
    
    private func getFakeNavigationViewModelMock() -> NavigationViewModelMock {
        
        let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)
        let dummyPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyLocalizationPolicyUseCase = mock(LocalizationPolicyUseCase.self)
        let dummyGetSystemStatusUseCase = mock(GetSystemStatusUseCase.self)
        let dummyLocalStorageRepository = mock(LocalStorageRepository.self)
        
        return mock(NavigationViewModel.self)
            .initialize(
                dummyAuthenticationUseCase,
                dummyPlayerDataUseCase,
                dummyLocalizationPolicyUseCase,
                dummyGetSystemStatusUseCase,
                dummyLocalStorageRepository
            )
    }
    
    private func getFakeServiceStatusViewModelMock() -> ServiceStatusViewModelMock {
        
        let dummyGetSystemStatusUseCase = mock(GetSystemStatusUseCase.self)
        let dummyLocalStorageRepository = mock(LocalStorageRepository.self)
        
        given(dummyGetSystemStatusUseCase.getOtpStatus()) ~> .just(.init(isMailActive: false, isSmsActive: false))
        given(dummyGetSystemStatusUseCase.getCustomerServiceEmail()) ~> .just("")
        given(dummyGetSystemStatusUseCase.getYearOfCopyRight()) ~> .just("")
        given(dummyGetSystemStatusUseCase.observePortalMaintenanceState()) ~> .never()
        
        return mock(ServiceStatusViewModel.self)
            .initialize(
                systemStatusUseCase: dummyGetSystemStatusUseCase,
                localStorageRepo: dummyLocalStorageRepository
            )
    }
    
    private func getFakePlayerViewModelMock() -> PlayerViewModelMock {
        
        let dummyPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)
        
        return mock(PlayerViewModel.self)
            .initialize(
                playerUseCase: dummyPlayerDataUseCase,
                authUseCase: dummyAuthenticationUseCase)
    }

    func test_givenUserLoggedInAndUnexpired_whenColdStart_thenEnterLobbyPage() {
        
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false

        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> self.loggedPlayer
        
        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo
        )

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

        sut.loadViewIfNeeded()
        sut.executeNavigation()

        verify(
            mockNavigator.goTo(
                productType: .casino,
                isMaintenance: any()
            )
        )
        .wasCalled()
    }

    func test_givenUserLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
        
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true
        
        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> self.loggedPlayer
        
        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo
        )

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

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
        
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false
        
        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> nil

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo
        )
        
        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

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

        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true
        
        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> nil

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo
        )
        
        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

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
    
    func test_givenUserLoggedInAndAllMaintenance_whenColdStart_thenEnterMaintenancePage() {
        
        stubMaintenanceStatus(isAllMaintenance: true)

        NavigationManagement.sharedInstance = mockNavigator

        let sut = CasinoViewController.initFrom(storyboard: "Casino")

        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)
        
        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasCalled()
    }
    
    func test_givenUserNotLoggedInAndAllMaintenance_whenColdStart_thenEnterMaintenancePage() {
        
        stubMaintenanceStatus(isAllMaintenance: true)
        
        NavigationManagement.sharedInstance = mockNavigator

        let sut = NewLoginViewController.initFrom(storyboard: "Login")

        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)
        
        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasCalled()
    }

    func test_givenUserLoggedInAndNoAllMaintenance_whenHotStart_thenNotEnterMaintenancePage() {
        
        stubLoginStatus(isLogged: true)
        stubMaintenanceStatus(isAllMaintenance: false)
        
        NavigationManagement.sharedInstance = mockNavigator

        simulateApplicationWillEnterForeground()

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasNeverCalled()
    }
    
    func test_givenUserLoggedInAndAllMaintenance_whenHotStart_thenEnterMaintenancePage() {
        
        stubLoginStatus(isLogged: true)
        stubMaintenanceStatus(isAllMaintenance: true)

        NavigationManagement.sharedInstance = mockNavigator
        
        let sut = CasinoViewController.initFrom(storyboard: "Casino")
        
        makeItVisible(sut)
        
        simulateApplicationWillEnterForeground()
        
        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasCalled()
    }

    func test_givenUserNotLoggedInAndNoAllMaintenance_whenHotStart_thenNotEnterMaintenancePage() {
        
        stubLoginStatus(isLogged: false)
        stubMaintenanceStatus(isAllMaintenance: false)
        
        NavigationManagement.sharedInstance = mockNavigator

        simulateApplicationWillEnterForeground()

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasNeverCalled()
    }

    func test_givenUserNotLoggedInAndAllMaintenance_whenHotStart_thenEnterMaintenancePage() {
        
        stubLoginStatus(isLogged: false)
        stubMaintenanceStatus(isAllMaintenance: true)
        
        let sut = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LandingNavigation")
        
        makeItVisible(sut)
        
        NavigationManagement.sharedInstance = mockNavigator
        
        simulateApplicationWillEnterForeground()

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"
            )
        )
        .wasCalled()
    }
}
