import Mockingbird
import Moya
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios

@MainActor
final class LaunchAppTest: XCBaseTestCase {
    private let loggedPlayer = PlayerInfoCacheBean(
        displayID: "",
        gamerID: "",
        locale: "",
        level: 1,
        defaultProduct: 3)

    private lazy var mockNavigator = mock(Navigator.self)
    private lazy var mockAlert = mock(AlertProtocol.self)
  
    override func tearDown() {
        super.tearDown()
        reset(mockNavigator, mockAlert)
    }

    private func simulateApplicationWillEnterForeground() {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillEnterForeground(UIApplication.shared)
    }

    private func makeLaunchSUT() -> LaunchViewController {
        .initFrom(storyboard: "Launch")
    }

    private func getFakeNavigationViewModel(
        stubAuthenticationUseCase: AuthenticationUseCaseMock = mock(AuthenticationUseCase.self),
        stubPlayerDataUseCase: PlayerDataUseCaseMock = mock(PlayerDataUseCase.self),
        stubLocalizationPolicyUseCase: LocalizationPolicyUseCaseMock = mock(LocalizationPolicyUseCase.self),
        stubGetSystemStatusUseCase: ISystemStatusUseCaseMock = mock(ISystemStatusUseCase.self),
        stubLocalStorageRepository: LocalStorageRepositoryMock = mock(LocalStorageRepository.self))
        -> NavigationViewModel
    {
        .init(
            stubAuthenticationUseCase,
            stubPlayerDataUseCase,
            stubLocalizationPolicyUseCase,
            stubGetSystemStatusUseCase,
            stubLocalStorageRepository)
    }

    private func stubLoginStatus(isLogged: Single<Bool>) {
        let stubNavigationViewModel = getFakeNavigationViewModelMock()
        given(stubNavigationViewModel.checkIsLogged()) ~> isLogged

        let stubPlayerViewModel = getFakePlayerViewModelMock()
        given(stubPlayerViewModel.checkIsLogged()) ~> isLogged
        given(stubPlayerViewModel.logout()) ~> Single<Void>.just(()).asCompletable

        Injectable.register(NavigationViewModel.self) { _ in
            stubNavigationViewModel
        }

        Injectable.register(PlayerViewModel.self) { _ in
            stubPlayerViewModel
        }
    }

    private func stubMaintenanceStatus(isAllMaintenance: Bool) {
        let stubSystemUseCase = mock(ISystemStatusUseCase.self)

        given(stubSystemUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: true, isSmsActive: true))
        given(stubSystemUseCase.isOtpServiceAvaiable()) ~> .just(.init(isMailActive: true, isSmsActive: true))
        given(stubSystemUseCase.fetchCustomerServiceEmail()) ~> .just("")

        if isAllMaintenance {
            given(stubSystemUseCase.fetchMaintenanceStatus()) ~> .just(MaintenanceStatus.AllPortal(remainingSeconds: nil))
            given(stubSystemUseCase.observeMaintenanceStatusByFetch()) ~>
                .just(MaintenanceStatus.AllPortal(remainingSeconds: nil))
            given(stubSystemUseCase.observeMaintenanceStatusChange()) ~> .just(())
        }
        else {
            given(stubSystemUseCase.fetchMaintenanceStatus()) ~> .just(.Product(productsAvailable: [], status: [:]))
            given(stubSystemUseCase.observeMaintenanceStatusByFetch()) ~> .just(.Product(productsAvailable: [], status: [:]))
            given(stubSystemUseCase.observeMaintenanceStatusChange()) ~> .just(())
        }

        Injectable.register(ISystemStatusUseCase.self) { _ in
            stubSystemUseCase
        }
    }

    private func getFakeNavigationViewModelMock() -> NavigationViewModelMock {
        let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)
        let dummyPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyLocalizationPolicyUseCase = mock(LocalizationPolicyUseCase.self)
        let dummyGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let dummyLocalStorageRepository = mock(LocalStorageRepository.self)

        return mock(NavigationViewModel.self)
            .initialize(
                dummyAuthenticationUseCase,
                dummyPlayerDataUseCase,
                dummyLocalizationPolicyUseCase,
                dummyGetSystemStatusUseCase,
                dummyLocalStorageRepository)
    }

    private func getFakePlayerViewModelMock() -> PlayerViewModelMock {
        let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)

        return mock(PlayerViewModel.self).initialize(authUseCase: dummyAuthenticationUseCase)
    }

    private func getStubCasinoViewModel() -> CasinoViewModel {
        let stubCasinoUseCase = mock(CasinoUseCase.self)
        given(stubCasinoUseCase.getLobbies()) ~> .just([])
        given(stubCasinoUseCase.checkBonusAndCreateGame(any())) ~> .just(.inactive)
        given(stubCasinoUseCase.searchGamesByTag(tags: any())) ~> .just([])

        let stubViewModel = CasinoViewModel(
            mock(CasinoRecordUseCase.self),
            stubCasinoUseCase,
            mock(MemoryCacheImpl.self),
            mock(AbsCasinoAppService.self),
            mock(AbsCasinoAppService.self))
        stubViewModel.tagStates = .just([])

        return stubViewModel
    }
  
    private func getFakeSideMenuViewModel() -> SideMenuViewModelMock {
        let fakeViewModel = mock(SideMenuViewModel.self)
        given(fakeViewModel.observePlayerInfo()) ~> .just(.init(
            displayID: "1234567890",
            gamerID: "",
            level: 1,
            defaultProduct: .sbk))
        given(fakeViewModel.observePlayerBalance()) ~> .just("123".toAccountCurrency())
        given(fakeViewModel.getSupportLoacle()) ~> .China()
        given(fakeViewModel.loadBalanceHiddenState(by: any())) ~> false
        given(fakeViewModel.errors()) ~> .empty()
        given(fakeViewModel.observeKickOutSignal()) ~> .never()
    
        return fakeViewModel
    }

    func test_givenUserLoggedInAndUnexpired_whenColdStart_thenEnterLobbyPage() async {
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false

        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> self.loggedPlayer

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo)

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

        sut.loadViewIfNeeded()
        await sut.executeNavigation()

        verify(
            mockNavigator.goTo(
                productType: .casino,
                isMaintenance: any()))
            .wasCalled()
    }

    func test_givenUserLoggedInAndExpired_whenColdStart_thenEnterLandingPage() async {
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true

        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> self.loggedPlayer

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo)

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

        sut.loadViewIfNeeded()
        await sut.executeNavigation(videoURL: nil)

        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"))
            .wasCalled()
    }

    func test_givenUserNotLoggedInAndUnexpired_whenColdStart_thenEnterLandingPage() async {
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> false

        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> nil

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo)

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

        sut.loadViewIfNeeded()
        await sut.executeNavigation(videoURL: nil)

        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"))
            .wasCalled()
    }

    func test_givenUserNotLoggedInAndExpired_whenColdStart_thenEnterLandingPage() async {
        let stubAuthUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthUseCase.isLastAPISuccessDateExpire()) ~> true

        let stubLocalStorageRepo = mock(LocalStorageRepository.self)
        given(stubLocalStorageRepo.getPlayerInfo()) ~> nil

        let stubNavigationViewModel = getFakeNavigationViewModel(
            stubAuthenticationUseCase: stubAuthUseCase,
            stubLocalStorageRepository: stubLocalStorageRepo)

        NavigationManagement.sharedInstance = mockNavigator

        let sut = makeLaunchSUT()
        sut.viewModel = stubNavigationViewModel

        sut.loadViewIfNeeded()
        await sut.executeNavigation(videoURL: nil)

        verify(
            mockNavigator.goTo(
                storyboard: "Login",
                viewControllerId: "LandingNavigation"))
            .wasCalled()
    }

    func test_givenUserLoggedInAndAllMaintenance_whenColdStart_thenShowMaintenanceAlert() {
        stubLoginStatus(isLogged: .just(true))
        stubMaintenanceStatus(isAllMaintenance: true)

        Alert.shared = mockAlert
    
        let sut = SideBarViewController.initFrom(storyboard: "slideMenu")
        sut.sideMenuViewModel = getFakeSideMenuViewModel()
    
        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)
        sut.observeSystemStatus()
    
        wait(for: 1)
    
        verify(mockAlert.show(
            Localize.string("common_urgent_maintenance"),
            Localize.string("common_maintenance_logout"),
            confirm: any(),
            confirmText: any(),
            cancel: any(),
            cancelText: any(),
            tintColor: any()))
            .wasCalled()
    }

//    func test_givenUserNotLoggedInAndAllMaintenance_whenColdStart_thenEnterMaintenancePage() {
//        stubMaintenanceStatus(isAllMaintenance: true)
//
//        NavigationManagement.sharedInstance = mockNavigator
//
//        let sut = LandingAppViewController.initFrom(storyboard: "Login")
//
//        sut.loadViewIfNeeded()
//        sut.viewWillAppear(true)
//
//        verify(
//            mockNavigator.goTo(
//                storyboard: "Maintenance",
//                viewControllerId: "PortalMaintenanceViewController"))
//            .wasCalled()
//    }

    func test_givenUserLoggedInAndNoAllMaintenance_whenHotStart_thenNotEnterMaintenancePage() {
        stubLoginStatus(isLogged: .just(true))
        stubMaintenanceStatus(isAllMaintenance: false)

        NavigationManagement.sharedInstance = mockNavigator

        simulateApplicationWillEnterForeground()

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"))
            .wasNeverCalled()
    }

    func test_givenUserLoggedInAndAllMaintenance_whenHotStart_thenEnterMaintenancePage() {
        stubLoginStatus(isLogged: .error(MoyaError.statusCode(Response(statusCode: 410, data: Data()))))
        stubMaintenanceStatus(isAllMaintenance: true)

        NavigationManagement.sharedInstance = mockNavigator
    
        let sut = SideBarViewController.initFrom(storyboard: "slideMenu")
        sut.sideMenuViewModel = getFakeSideMenuViewModel()
    
        makeItVisible(sut)

        simulateApplicationWillEnterForeground()
    
        sut.loadViewIfNeeded()
        sut.viewDidAppear(true)
    
        wait(for: 1)
    
        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"))
            .wasCalled()
    }

    func test_givenUserNotLoggedInAndNoAllMaintenance_whenHotStart_thenNotEnterMaintenancePage() {
        stubLoginStatus(isLogged: .just(false))
        stubMaintenanceStatus(isAllMaintenance: false)

        NavigationManagement.sharedInstance = mockNavigator

        simulateApplicationWillEnterForeground()

        verify(
            mockNavigator.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController"))
            .wasNeverCalled()
    }

//    func test_givenUserNotLoggedInAndAllMaintenance_whenHotStart_thenEnterMaintenancePage() {
//        stubLoginStatus(isLogged: .just(false))
//        stubMaintenanceStatus(isAllMaintenance: true)
//
//        let sut = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LandingNavigation")
//
//        makeItVisible(sut)
//
//        NavigationManagement.sharedInstance = mockNavigator
//
//        simulateApplicationWillEnterForeground()
//    
//        wait(for: 1)
//
//        verify(
//            mockNavigator.goTo(
//                storyboard: "Maintenance",
//                viewControllerId: "PortalMaintenanceViewController"))
//            .wasCalled()
//    }
}
