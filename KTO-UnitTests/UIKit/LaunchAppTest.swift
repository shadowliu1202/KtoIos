import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class LaunchAppTest: XCBaseTestCase {
  private let loggedPlayer = PlayerInfoCache(
    account: "",
    ID: "",
    locale: "",
    VIPLevel: 1,
    defaultProduct: 3)

  private lazy var mockNavigator = mock(Navigator.self)

  override func tearDown() {
    super.tearDown()
    reset(mockNavigator)
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
    stubLocalStorageRepository: LocalStorageRepositoryMock = mock(LocalStorageRepository.self))
    -> NavigationViewModel
  {
    NavigationViewModel(
      stubAuthenticationUseCase,
      stubPlayerDataUseCase,
      stubLocalizationPolicyUseCase,
      stubGetSystemStatusUseCase,
      stubLocalStorageRepository)
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
    let stubGetSystemStatusUseCase = mock(GetSystemStatusUseCase.self)

    given(stubGetSystemStatusUseCase.getOtpStatus()) ~> .just(.init(isMailActive: true, isSmsActive: true))
    given(stubGetSystemStatusUseCase.getCustomerServiceEmail()) ~> .just("")

    if isAllMaintenance {
      given(stubGetSystemStatusUseCase.fetchMaintenanceStatus()) ~> .just(MaintenanceStatus.AllPortal(remainingSeconds: nil))
      given(stubGetSystemStatusUseCase.observePortalMaintenanceState()) ~>
        .just(MaintenanceStatus.AllPortal(remainingSeconds: nil))
    }
    else {
      given(stubGetSystemStatusUseCase.fetchMaintenanceStatus()) ~> .just(.Product(productsAvailable: [], status: [:]))
      given(stubGetSystemStatusUseCase.observePortalMaintenanceState()) ~> .just(.Product(productsAvailable: [], status: [:]))
    }

    Injectable.register(GetSystemStatusUseCase.self) { _ in
      stubGetSystemStatusUseCase
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
        dummyLocalStorageRepository)
  }

  private func getFakePlayerViewModelMock() -> PlayerViewModelMock {
    let dummyPlayerDataUseCase = mock(PlayerDataUseCase.self)
    let dummyAuthenticationUseCase = mock(AuthenticationUseCase.self)

    return mock(PlayerViewModel.self)
      .initialize(
        playerUseCase: dummyPlayerDataUseCase,
        authUseCase: dummyAuthenticationUseCase)
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
      mock(AbsCasinoAppService.self))
    stubViewModel.tagStates = .just([])

    return stubViewModel
  }

  func test_givenUserLoggedInAndUnexpired_whenColdStart_thenEnterLobbyPage() {
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
    sut.executeNavigation()

    verify(
      mockNavigator.goTo(
        productType: .casino,
        isMaintenance: any()))
      .wasCalled()
  }

  func test_givenUserLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
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
    sut.executeNavigation()

    simulateAnimationEnd()

    verify(
      mockNavigator.goTo(
        storyboard: "Login",
        viewControllerId: "LandingNavigation"))
      .wasCalled()
  }

  func test_givenUserNotLoggedInAndUnexpired_whenColdStart_thenEnterLandingPage() {
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
    sut.executeNavigation()

    simulateAnimationEnd()

    verify(
      mockNavigator.goTo(
        storyboard: "Login",
        viewControllerId: "LandingNavigation"))
      .wasCalled()
  }

  func test_givenUserNotLoggedInAndExpired_whenColdStart_thenEnterLandingPage() {
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
    sut.executeNavigation()

    simulateAnimationEnd()

    verify(
      mockNavigator.goTo(
        storyboard: "Login",
        viewControllerId: "LandingNavigation"))
      .wasCalled()
  }

  func test_givenUserLoggedInAndAllMaintenance_whenColdStart_thenEnterMaintenancePage() {
    stubLoginStatus(isLogged: true)
    stubMaintenanceStatus(isAllMaintenance: true)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = CasinoViewController.initFrom(storyboard: "Casino")
    sut.viewModel = getStubCasinoViewModel()

    sut.loadViewIfNeeded()
    sut.viewDidAppear(true)

    verify(
      mockNavigator.goTo(
        storyboard: "Maintenance",
        viewControllerId: "PortalMaintenanceViewController"))
      .wasCalled()
  }

  func test_givenUserNotLoggedInAndAllMaintenance_whenColdStart_thenEnterMaintenancePage() {
    stubMaintenanceStatus(isAllMaintenance: true)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = LoginViewController.initFrom(storyboard: "Login")

    sut.loadViewIfNeeded()
    sut.viewWillAppear(true)

    verify(
      mockNavigator.goTo(
        storyboard: "Maintenance",
        viewControllerId: "PortalMaintenanceViewController"))
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
        viewControllerId: "PortalMaintenanceViewController"))
      .wasNeverCalled()
  }

  func test_givenUserLoggedInAndAllMaintenance_whenHotStart_thenEnterMaintenancePage() {
    stubLoginStatus(isLogged: true)
    stubMaintenanceStatus(isAllMaintenance: true)

    NavigationManagement.sharedInstance = mockNavigator

    let sut = CasinoViewController.initFrom(storyboard: "Casino")
    sut.viewModel = getStubCasinoViewModel()

    makeItVisible(sut)

    simulateApplicationWillEnterForeground()

    sut.loadViewIfNeeded()
    sut.viewDidAppear(true)

    verify(
      mockNavigator.goTo(
        storyboard: "Maintenance",
        viewControllerId: "PortalMaintenanceViewController"))
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
        viewControllerId: "PortalMaintenanceViewController"))
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
        viewControllerId: "PortalMaintenanceViewController"))
      .wasCalled()
  }
}
