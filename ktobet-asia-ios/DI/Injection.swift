import Foundation
import RxSwift
import sharedbu
import Swinject

final class Injection {
  static let shared = Injection()

  private(set) var container = Container()

  let networkReadyRelay = BehaviorRelay(value: false)
  
  private init() {
    HelperKt.doInitKoin()

    registerAllDependency()
  }

  func registerAllDependency() {
    registerFakeNetworkInfa()
    registerCustomServicePresenter()
    registApi()
    registRepo()
    registUsecase()
    registNavigator()
    registViewModel()
    registSingleton()

    registersharedbuModule()
  }

  // MARK: - Setup Network Infa
  
  func setupNetworkInfa() async {
    let ktoURLManager = KtoURLManager()
    await ktoURLManager.checkHosts()
    
    let cookieManager = CookieManager(
      allHosts: Configuration.hostName.values.flatMap { $0 },
      currentURL: ktoURLManager.portalURL,
      currentDomain: ktoURLManager.currentDomain)

    registerKtoURLManager(ktoURLManager)
    registerCookieManager(cookieManager)

    registerHttpClient(
      cookieManager: cookieManager,
      portalURL: ktoURLManager.portalURL,
      versionUpdateURL: ktoURLManager.versionUpdateURL)
    
    networkReadyRelay.accept(true)
  }
  
  private func registerKtoURLManager(_ ktoURLManager: KtoURLManager) {
    container
      .register(KtoURLManager.self) { _ in ktoURLManager }
      .inObjectScope(.application)
  }
  
  private func registerCookieManager(_ cookieManager: CookieManager) {
    container
      .register(CookieManager.self) { _ in cookieManager }
      .inObjectScope(.application)
  }
  
  // MARK: - HttpClient
  
  private func registerFakeNetworkInfa() {
    let fakeURL = URL(string: "https://")!
    
    container
      .register(CookieManager.self) { _ in CookieManager(allHosts: [], currentURL: fakeURL, currentDomain: "") }
      .inObjectScope(.application)
    
    lazy var fakeHttpClient = HttpClient(
      container.resolveWrapper(LocalStorageRepository.self),
      container.resolveWrapper(CookieManager.self),
      currentURL: fakeURL,
      locale: container.resolveWrapper(PlayerConfiguration.self).supportLocale)
    
    container.register(HttpClient.self) { _ in fakeHttpClient }
    container.register(HttpClient.self, name: "update") { _ in fakeHttpClient }
  }
  
  func registerHttpClient(cookieManager: CookieManager, portalURL: URL, versionUpdateURL: URL) {
    container
      .register(HttpClient.self) {
        HttpClient(
          $0.resolveWrapper(LocalStorageRepository.self),
          cookieManager,
          currentURL: portalURL,
          locale: $0.resolveWrapper(PlayerConfiguration.self).supportLocale)
      }
      .inObjectScope(.locale)

    container
      .register(HttpClient.self, name: "update") {
        HttpClient(
          $0.resolveWrapper(LocalStorageRepository.self),
          cookieManager,
          currentURL: versionUpdateURL,
          locale: $0.resolveWrapper(PlayerConfiguration.self).supportLocale)
      }
      .inObjectScope(.locale)
  }

  // MARK: - CustomerServicePresenter
  
  func registerCustomServicePresenter() {
    container
      .register(CustomServicePresenter.self) { resolver in
        let csViewModel = resolver.resolveWrapper(CustomerServiceViewModel.self)
        return CustomServicePresenter(csViewModel)
      }
      .inObjectScope(.locale)
  }

  // MARK: - API
  
  func registApi() {
    container
      .register(NotificationApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return NotificationApi(httpClient)
      }
    container
      .register(AuthenticationApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return AuthenticationApi(httpClient)
      }
    container
      .register(PlayerApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return PlayerApi(httpClient)
      }
    container
      .register(VersionUpdateApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self, name: "update")
        return VersionUpdateApi(httpClient)
      }
    container
      .register(PortalApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return PortalApi(httpClient)
      }
    container
      .register(GameApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return GameApi(httpClient)
      }
    container
      .register(BankApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return BankApi(httpClient)
      }
    container
      .register(ImageApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return ImageApi(httpClient)
      }
    container
      .register(CasinoApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return CasinoApi(httpClient)
      }
    container
      .register(SlotApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return SlotApi(httpClient)
      }
    container
      .register(NumberGameApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return NumberGameApi(httpClient)
      }
    container
      .register(P2PApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return P2PApi(httpClient)
      }
    container
      .register(ArcadeApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return ArcadeApi(httpClient)
      }
    container
      .register(PromotionApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return PromotionApi(httpClient)
      }
  }

  // MARK: - Repo
  
  func registRepo() {
    container
      .register(PlayerRepository.self) {
        PlayerRepositoryImpl(
          $0.resolveWrapper(HttpClient.self),
          $0.resolveWrapper(PlayerApi.self),
          $0.resolveWrapper(PortalApi.self),
          $0.resolveWrapper(SettingStore.self),
          $0.resolveWrapper(LocalStorageRepository.self),
          $0.resolveWrapper(MemoryCacheImpl.self),
          $0.resolveWrapper(DefaultProductProtocol.self))
      }

    container
      .register(NotificationRepository.self) { resolver in
        let notificationApi = resolver.resolveWrapper(NotificationApi.self)
        return NotificationRepositoryImpl(notificationApi)
      }

    container
      .register(GameInfoRepository.self) { resolver in
        let gameApi = resolver.resolveWrapper(GameApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return GameInfoRepositoryImpl(gameApi, httpClient)
      }

    container
      .register(IAuthRepository.self) { resolver in
        IAuthRepositoryImpl(
          resolver.resolveWrapper(AuthenticationApi.self),
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CookieManager.self))
      }

    container
      .register(SystemRepository.self) { resolver in
        SystemRepositoryImpl(
          resolver.resolveWrapper(PortalApi.self),
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CookieManager.self))
      }

    container
      .register(ResetPasswordRepository.self) { resolver in
        IAuthRepositoryImpl(
          resolver.resolveWrapper(AuthenticationApi.self),
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CookieManager.self))
      }

    container
      .register(LocalStorageRepository.self) { _ in
        LocalStorageRepositoryImpl()
      }

    container
      .register(SettingStore.self) { _ in
        SettingStore()
      }

    container
      .register(ImageRepository.self) { resolver in
        let imageApi = resolver.resolveWrapper(ImageApi.self)
        return ImageRepositoryImpl(imageApi)
      }

    container
      .register(BankRepository.self) { resolver in
        let bankApi = resolver.resolveWrapper(BankApi.self)
        return BankRepositoryImpl(bankApi)
      }

    container
      .register(CasinoRecordRepository.self) {
        CasinoRecordRepositoryImpl(
          $0.resolveWrapper(CasinoApi.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(CasinoRepository.self) { resolver in
        let casinoApi = resolver.resolveWrapper(CasinoApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return CasinoRepositoryImpl(
          casinoApi,
          httpClient: httpClient)
      }

    container
      .register(SlotRepository.self) { resolver in
        let slotApi = resolver.resolveWrapper(SlotApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return SlotRepositoryImpl(
          slotApi,
          httpClient: httpClient)
      }

    container
      .register(SlotRecordRepository.self) {
        SlotRecordRepositoryImpl(
          $0.resolveWrapper(SlotApi.self),
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(HttpClient.self))
      }

    container
      .register(NumberGameRepository.self) { resolver in
        let numberGameApi = resolver.resolveWrapper(NumberGameApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return NumberGameRepositoryImpl(
          numberGameApi,
          httpClient: httpClient)
      }

    container
      .register(NumberGameRecordRepository.self) { resolver in
        let numberGameApi = resolver.resolveWrapper(NumberGameApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return NumberGameRecordRepositoryImpl(
          numberGameApi,
          httpClient: httpClient)
      }

    container
      .register(P2PRepository.self) { resolver in
        let p2pApi = resolver.resolveWrapper(P2PApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return P2PRepositoryImpl(
          p2pApi,
          httpClient: httpClient)
      }

    container
      .register(P2PRecordRepository.self) {
        P2PRecordRepositoryImpl(
          $0.resolveWrapper(P2PApi.self),
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(HttpClient.self))
      }

    container
      .register(ArcadeRecordRepository.self) {
        ArcadeRecordRepositoryImpl(
          $0.resolveWrapper(ArcadeApi.self),
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(HttpClient.self))
      }

    container
      .register(ArcadeRepository.self) { resolver in
        let arcadeApi = resolver.resolveWrapper(ArcadeApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return ArcadeRepositoryImpl(
          arcadeApi,
          httpClient: httpClient)
      }

    container
      .register(PromotionRepository.self) { resolver in
        let promotionApi = resolver.resolveWrapper(PromotionApi.self)
        return PromotionRepositoryImpl(promotionApi)
      }

    container
      .register(AccountPatternGenerator.self) {
        AccountPatternGeneratorFactory.create(
          $0.resolveWrapper(PlayerConfiguration.self).supportLocale)
      }

    container
      .register(LocalizationRepository.self) {
        LocalizationRepositoryImpl(
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(PortalApi.self))
      }

    container
      .register(AppUpdateRepository.self) { resolver in
        let versionUpdateApi = resolver.resolveWrapper(VersionUpdateApi.self)
        return AppUpdateRepositoryImpl(versionUpdateApi)
      }

    container
      .register(MemoryCacheImpl.self) { _ in
        MemoryCacheImpl()
      }
      .inObjectScope(.locale)

    container
      .register(ApplicationStorable.self) { _ in
        ApplicationStorage()
      }
      .inObjectScope(.application)

    container
      .register(KeychainStorable.self) { _ in
        Keychain()
      }
      .inObjectScope(.application)

    container
      .register(SignalRepository.self) { resolver in
        SignalRepositoryImpl(
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CookieManager.self))
      }
      .inObjectScope(.locale)
  }

  // MARK: - UseCase
  
  func registUsecase() {
    container
      .register(RegisterUseCase.self) { resolver in
        let auth = resolver.resolveWrapper(IAuthRepository.self)
        let player = resolver.resolveWrapper(PlayerRepository.self)
        return RegisterUseCaseImpl(auth, player)
      }

    container
      .register(ConfigurationUseCase.self) {
        ConfigurationUseCaseImpl(
          $0.resolveWrapper(PlayerRepository.self),
          $0.resolveWrapper(LocalStorageRepository.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(AuthenticationUseCase.self) { resolver in
        let repoAuth = resolver.resolveWrapper(IAuthRepository.self)
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
        let settingStore = resolver.resolveWrapper(SettingStore.self)
        return AuthenticationUseCaseImpl(
          authRepository: repoAuth,
          playerRepository: repoPlayer,
          localStorageRepo: repoLocalStorage,
          settingStore: settingStore)
      }

    container
      .register(ISystemStatusUseCase.self) { resolver in
        SystemStatusUseCase(
          resolver.resolveWrapper(SystemRepository.self),
          resolver.resolveWrapper(SignalRepository.self))
      }

    container
      .register(ResetPasswordUseCase.self) { resolver in
        let repoSystem = resolver.resolveWrapper(ResetPasswordRepository.self)
        let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)

        return ResetPasswordUseCaseImpl(
          repoSystem,
          localRepository: repoLocal)
      }

    container
      .register(PlayerDataUseCase.self) {
        PlayerDataUseCaseImpl(
          $0.resolveWrapper(PlayerRepository.self),
          $0.resolveWrapper(LocalStorageRepository.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(NotificationUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(NotificationRepository.self)
        return NotificationUseCaseImpl(repo)
      }

    container
      .register(UploadImageUseCase.self) { resolver in
        let repoImage = resolver.resolveWrapper(ImageRepository.self)
        return UploadImageUseCaseImpl(repoImage)
      }

    container
      .register(BankUseCase.self) { resolver in
        let repoBank = resolver.resolveWrapper(BankRepository.self)
        return BankUseCaseImpl(repoBank)
      }

    container
      .register(CasinoRecordUseCase.self) { resolver in
        let repoCasinoRecord = resolver.resolveWrapper(CasinoRecordRepository.self)
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        return CasinoRecordUseCaseImpl(repoCasinoRecord, playerRepository: repoPlayer)
      }

    container
      .register(CasinoUseCase.self) {
        CasinoUseCaseImpl(
          $0.resolveWrapper(CasinoRepository.self),
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(PromotionRepository.self))
      }

    container
      .register(SlotUseCase.self) { resolver in
        SlotUseCaseImpl(
          slotRepository: resolver.resolveWrapper(SlotRepository.self),
          localRepository: resolver.resolveWrapper(LocalStorageRepository.self),
          promotionRepository: resolver.resolveWrapper(PromotionRepository.self))
      }

    container
      .register(SlotRecordUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(SlotRecordRepository.self)
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        return SlotRecordUseCaseImpl(repo, playerRepository: repoPlayer)
      }

    container
      .register(NumberGameUseCase.self) { resolver in
        NumberGameUseCasaImp(
          numberGameRepository: resolver.resolveWrapper(NumberGameRepository.self),
          localRepository: resolver.resolveWrapper(LocalStorageRepository.self),
          promotionRepository: resolver.resolveWrapper(PromotionRepository.self))
      }

    container
      .register(NumberGameRecordUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(NumberGameRecordRepository.self)
        return NumberGameRecordUseCaseImpl(numberGameRecordRepository: repo)
      }

    container
      .register(P2PUseCase.self) { resolver in
        P2PUseCaseImpl(
          p2pRepository: resolver.resolveWrapper(P2PRepository.self),
          promotionRepository: resolver.resolveWrapper(PromotionRepository.self))
      }

    container
      .register(P2PRecordUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(P2PRecordRepository.self)
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        return P2PRecordUseCaseImpl(repo, repoPlayer)
      }

    container
      .register(ArcadeRecordUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(ArcadeRecordRepository.self)
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        return ArcadeRecordUseCaseImpl(repo, repoPlayer)
      }

    container
      .register(ArcadeUseCase.self) { resolver in
        ArcadeUseCaseImpl(
          arcadeRepository: resolver.resolveWrapper(ArcadeRepository.self),
          promotionRepository: resolver.resolveWrapper(PromotionRepository.self))
      }

    container
      .register(PromotionUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(PromotionRepository.self)
        let player = resolver.resolveWrapper(PlayerRepository.self)

        return PromotionUseCaseImpl(
          repo,
          playerRepository: player)
      }

    container
      .register(LocalizationPolicyUseCase.self) { resolver in
        let repoLocalization = resolver.resolveWrapper(LocalizationRepository.self)
        return LocalizationPolicyUseCaseImpl(repoLocalization)
      }

    container
      .register(AppVersionUpdateUseCase.self) {
        AppVersionUpdateUseCaseImpl(
          $0.resolveWrapper(AppUpdateRepository.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }
  }

  // MARK: - Navigator
  
  func registNavigator() {
    container
      .register(DepositNavigator.self) { _ in
        DepositNavigatorImpl()
      }
  }

  // MARK: - ViewModel
  
  func registViewModel() {
    container
      .register(CryptoDepositViewModel.self) { resolver in
        CryptoDepositViewModel(
          depositService: resolver.resolveWrapper(IDepositAppService.self))
      }

    container
      .register(DepositViewModel.self) { resolver in
        .init(
          depositService: resolver.resolveWrapper(IDepositAppService.self))
      }

    container
      .register(DepositOfflineConfirmViewModel.self) { resolver in
        .init(
          depositService: resolver.resolveWrapper(IDepositAppService.self),
          locale: resolver.resolveWrapper(PlayerConfiguration.self).supportLocale)
      }

    container
      .register(DepositRecordDetailViewModel.self) { resolver in
        .init(
          depositService: resolver.resolveWrapper(IDepositAppService.self),
          imageUseCase: resolver.resolveWrapper(UploadImageUseCase.self),
          httpClient: resolver.resolveWrapper(HttpClient.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(NotificationViewModel.self) { resolver in
        let useCase = resolver.resolveWrapper(NotificationUseCase.self)
        let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        return NotificationViewModel(
          useCase: useCase,
          configurationUseCase: usecaseConfiguration,
          systemStatusUseCase: systemUseCase)
      }

    container
      .register(NavigationViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(AuthenticationUseCase.self),
          resolver.resolveWrapper(PlayerDataUseCase.self),
          resolver.resolveWrapper(LocalizationPolicyUseCase.self),
          resolver.resolveWrapper(ISystemStatusUseCase.self),
          resolver.resolveWrapper(LocalStorageRepository.self))
      }

    container
      .register(SignupUserInfoViewModel.self) { resolver in
        let registerUseCase = resolver.resolveWrapper(RegisterUseCase.self)
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        let pattern = resolver.resolveWrapper(AccountPatternGenerator.self)
        return SignupUserInfoViewModel(registerUseCase, systemUseCase, pattern)
      }

    container
      .register(SignupPhoneViewModel.self) { resolver in
        let usecase = resolver.resolveWrapper(RegisterUseCase.self)
        return SignupPhoneViewModel(usecase)
      }

    container
      .register(SignupEmailViewModel.self) { resolver in
        let usecaseRegister = resolver.resolveWrapper(RegisterUseCase.self)
        let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
        let usecaseAuthentication = resolver.resolveWrapper(AuthenticationUseCase.self)
        return SignupEmailViewModel(usecaseRegister, usecaseConfiguration, usecaseAuthentication)
      }

    container
      .register(DefaultProductViewModel.self) {
        DefaultProductViewModel(
          $0.resolveWrapper(ConfigurationUseCase.self),
          $0.resolveWrapper(ISystemStatusUseCase.self),
          $0.resolveWrapper(DefaultProductAppService.self))
      }

    container
      .register(ResetPasswordViewModel.self) {
        ResetPasswordViewModel(
          $0.resolveWrapper(ResetPasswordUseCase.self),
          $0.resolveWrapper(ISystemStatusUseCase.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(ServiceStatusViewModel.self) { resolver in
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        return ServiceStatusViewModel(systemStatusUseCase: systemUseCase, localStorageRepo: localStorageRepo)
      }

    container
      .register(PlayerViewModel.self) { resolver in
        .init(authUseCase: resolver.resolveWrapper(AuthenticationUseCase.self))
      }

    container
      .register(CasinoViewModel.self) { resolver in
        CasinoViewModel(
          resolver.resolveWrapper(CasinoRecordUseCase.self),
          resolver.resolveWrapper(CasinoUseCase.self),
          resolver.resolveWrapper(MemoryCacheImpl.self),
          resolver.resolveWrapper(ICasinoGameAppService.self),
          resolver.resolveWrapper(ICasinoMyBetAppService.self))
      }

    container
      .register(TurnoverAlertViewModel.self) { resolver in
        .init(locale: resolver.resolveWrapper(PlayerConfiguration.self).supportLocale)
      }

    container
      .register(SlotViewModel.self) { resolver in
        SlotViewModel(slotUseCase: resolver.resolveWrapper(SlotUseCase.self))
      }

    container
      .register(SlotBetViewModel.self) { resolver in
        SlotBetViewModel(
          slotUseCase: resolver.resolveWrapper(SlotUseCase.self),
          slotRecordUseCase: resolver.resolveWrapper(SlotRecordUseCase.self))
      }

    container
      .register(NumberGameViewModel.self) { resolver in
        .init(
          numberGameUseCase: resolver.resolveWrapper(NumberGameUseCase.self),
          memoryCache: resolver.resolveWrapper(MemoryCacheImpl.self),
          numberGameService: resolver.resolveWrapper(INumberGameAppService.self))
      }

    container
      .register(NumberGameRecordViewModel.self) { resolver in
        NumberGameRecordViewModel(numberGameRecordUseCase: resolver.resolveWrapper(NumberGameRecordUseCase.self))
      }

    container
      .register(P2PViewModel.self) { resolver in
        P2PViewModel(p2pUseCase: resolver.resolveWrapper(P2PUseCase.self))
      }

    container
      .register(P2PBetViewModel.self) { resolver in
        P2PBetViewModel(p2pRecordUseCase: resolver.resolveWrapper(P2PRecordUseCase.self))
      }

    container
      .register(ArcadeRecordViewModel.self) { resolver in
        ArcadeRecordViewModel(arcadeRecordUseCase: resolver.resolveWrapper(ArcadeRecordUseCase.self))
      }

    container
      .register(ArcadeViewModel.self) { resolver in
        .init(
          arcadeUseCase: resolver.resolveWrapper(ArcadeUseCase.self),
          memoryCache: resolver.resolveWrapper(MemoryCacheImpl.self),
          arcadeAppService: resolver.resolveWrapper(IArcadeAppService.self))
      }

    container
      .register(PromotionViewModel.self) { resolver in
        PromotionViewModel(
          promotionUseCase: resolver.resolveWrapper(PromotionUseCase.self),
          playerUseCase: resolver.resolveWrapper(PlayerDataUseCase.self))
      }

    container
      .register(PromotionHistoryViewModel.self) {
        PromotionHistoryViewModel(
          $0.resolveWrapper(PromotionUseCase.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(CustomerServiceViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ICustomerServiceAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self),
          resolver.resolveWrapper(Loading.self))
      }
      .inObjectScope(.locale)

    container
      .register(ChatHistoriesViewModel.self) { resolver in
        ChatHistoriesViewModel(
          resolver.resolveWrapper(IChatHistoryAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
    
    container
      .register(ChatHistoriesEditViewModel.self) { resolver in
        ChatHistoriesEditViewModel(
          resolver.resolveWrapper(IChatHistoryAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
    
    container
      .register(ChatRoomViewModel.self) { resolver in
        ChatRoomViewModel(
          resolver.resolveWrapper(IChatAppService.self),
          resolver.resolveWrapper(ISurveyAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(ChattingListViewModel.self) {
        ChattingListViewModel($0.resolveWrapper(HttpClient.self))
      }
      .inObjectScope(.locale)

    container
      .register(TermsViewModel.self) { resolver in
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        return TermsViewModel(
          localizationPolicyUseCase: resolver.resolveWrapper(LocalizationPolicyUseCase.self),
          systemStatusUseCase: systemUseCase)
      }
      .inObjectScope(.locale)

    container
      .register(ModifyProfileViewModel.self) { resolver in
        let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
        let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
        let withdrawalService = resolver.resolveWrapper(IWithdrawalAppService.self)
        let pattern = resolver.resolveWrapper(AccountPatternGenerator.self)
        return ModifyProfileViewModel(playerUseCase, usecaseConfiguration, withdrawalService, pattern)
      }

    container
      .register(CommonOtpViewModel.self) { resolver in
        let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
        return CommonOtpViewModel(usecaseConfiguration)
      }

    container
      .register(ConfigurationViewModel.self) {
        ConfigurationViewModel(
          $0.resolveWrapper(LocalStorageRepository.self),
          $0.resolveWrapper(DefaultProductAppService.self))
      }

    container
      .register(AppSynchronizeViewModel.self) { resolver in
        AppSynchronizeViewModel(
          appUpdateUseCase: resolver.resolveWrapper(AppVersionUpdateUseCase.self),
          appStorage: resolver.resolveWrapper(ApplicationStorable.self))
      }
      .inObjectScope(.application)

    container
      .register(StarMergerViewModelImpl.self) { resolver in
        .init(
          depositService: resolver.resolveWrapper(IDepositAppService.self))
      }

    container
      .register(LoginViewModel.self) {
        LoginViewModel(
          $0.resolveWrapper(AuthenticationUseCase.self),
          $0.resolveWrapper(ConfigurationUseCase.self),
          $0.resolveWrapper(NavigationViewModel.self),
          $0.resolveWrapper(LocalStorageRepository.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(CryptoGuideVNDViewModelImpl.self) { resolver in
        let localizationUseCase = resolver.resolveWrapper(LocalizationPolicyUseCase.self)
        return CryptoGuideVNDViewModelImpl(localizationPolicyUseCase: localizationUseCase)
      }

    container
      .register(DepositCryptoRecordDetailViewModel.self) { resolver in
        .init(depositService: resolver.resolveWrapper(IDepositAppService.self))
      }

    container
      .register(DepositLogSummaryViewModel.self) { resolver in
        .init(
          depositService: resolver.resolveWrapper(IDepositAppService.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(OfflinePaymentViewModel.self) {
        OfflinePaymentViewModel(
          $0.resolveWrapper(IDepositAppService.self),
          $0.resolveWrapper(PlayerDataUseCase.self),
          $0.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(OnlinePaymentViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(PlayerDataUseCase.self),
          resolver.resolveWrapper(IDepositAppService.self),
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(MaintenanceViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISystemStatusUseCase.self),
          resolver.resolveWrapper(AuthenticationUseCase.self))
      }
      .inObjectScope(.locale)

    container
      .register(LevelPrivilegeViewModel.self) { resolver in
        .init(playerUseCase: resolver.resolveWrapper(PlayerDataUseCase.self))
      }

    container
      .register(WithdrawalMainViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCryptoLimitViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalLogSummaryViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalRecordDetailViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          imageUseCase: resolver.resolveWrapper(UploadImageUseCase.self),
          httpClient: resolver.resolveWrapper(HttpClient.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCryptoRecordDetailViewModel.self) { resolver in
        .init(appService: resolver.resolveWrapper(IWithdrawalAppService.self))
      }

    container
      .register(WithdrawalFiatWalletsViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalFiatRequestStep1ViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerDataUseCase: resolver.resolveWrapper(PlayerDataUseCase.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalFiatRequestStep2ViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCryptoWalletsViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerConfig: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalFiatWalletDetailViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerDataUseCase: resolver.resolveWrapper(PlayerDataUseCase.self),
          playerConfigure: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCryptoWalletDetailViewModel.self) { resolver in
        .init(
          withdrawalService: resolver.resolveWrapper(IWithdrawalAppService.self),
          playerConfigure: resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCreateCryptoAccountViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalOTPVerifyMethodSelectViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISystemStatusUseCase.self),
          resolver.resolveWrapper(PlayerDataUseCase.self),
          resolver.resolveWrapper(PlayerConfiguration.self),
          resolver.resolveWrapper(IWithdrawalAppService.self))
      }

    container
      .register(WithdrawalOTPVerificationViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(PlayerConfiguration.self),
          resolver.resolveWrapper(PlayerDataUseCase.self),
          resolver.resolveWrapper(IWithdrawalAppService.self))
      }

    container.register(WithdrawalAddFiatBankCardViewModel.self) {
      WithdrawalAddFiatBankCardViewModel(
        $0.resolveWrapper(PlayerConfiguration.self),
        $0.resolveWrapper(AuthenticationUseCase.self),
        $0.resolveWrapper(BankUseCase.self),
        $0.resolveWrapper(PlayerDataUseCase.self),
        $0.resolveWrapper(AccountPatternGenerator.self),
        $0.resolveWrapper(IWithdrawalAppService.self))
    }

    container
      .register(WithdrawalCryptoRequestStep1ViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }

    container
      .register(WithdrawalCryptoRequestStep2ViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
    
    container
      .register(PrechatSurveyViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISurveyAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self),
          resolver.resolveWrapper(INetworkMonitor.self))
      }
    
    container
      .register(ExitSurveyViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISurveyAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
    
    container
      .register(TransactionLogViewModel.self) {
        .init(
          $0.resolveWrapper(ITransactionAppService.self),
          $0.resolveWrapper(ICasinoMyBetAppService.self),
          $0.resolveWrapper(IP2PAppService.self),
          $0.resolveWrapper(PlayerConfiguration.self),
          $0.resolveWrapper(PlayerRepository.self))
      }
    
    container
      .register(CustomerServiceMainViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IChatHistoryAppService.self),
          resolver.resolveWrapper(IChatAppService.self),
          resolver.resolveWrapper(ISurveyAppService.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CallingViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IChatAppService.self))
      }
    
    container
      .register(OfflineMessageViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISurveyAppService.self),
          resolver.resolveWrapper(AuthenticationUseCase.self))
      }
      .inObjectScope(.locale)
  }

  // MARK: - Singleton
  
  func registSingleton() {
    container
      .register(LocalizeUtils.self) { resolver in
        let cultureCode = resolver.resolveWrapper(PlayerConfiguration.self).supportLocale.cultureCode()
        return LocalizeUtils(localizationFileName: cultureCode)
      }
      .inObjectScope(.locale)

    container
      .register(AlertProtocol.self) { _ in
        Alert.shared
      }
      .inObjectScope(.application)

    container
      .register(Loading.self) { _ in
        LoadingImpl.shared
      }
      .inObjectScope(.application)

    container
      .register(SnackBar.self) { _ in
        SnackBarImpl.shared
      }
      .inObjectScope(.application)

    container
      .register(ActivityIndicator.self, name: "CheckingIsLogged") { _ in
        .init()
      }
      .inObjectScope(.application)
    
    container
      .register(INetworkMonitor.self) { _ in
        NetworkStateMonitor.shared
      }
      .inObjectScope(.application)
  }

  // MARK: - sharedbu
  
  func registersharedbuModule() {
    registerExternalProtocol()
    registerNumberGameModule()
    registerArcadeModule()
    registerWalletModule()
    registerCustomerServiceModule()
    registerCasinoModule()
    registerP2PModule()
    registerTransactionModule()
    registerPlayerSettingModule()
  }

  // MARK: - ExternalProtocol
  func registerExternalProtocol() {
    container
      .register(ExternalStringService.self) { _ in
        ExternalStringServiceFactory()
      }
      .inObjectScope(.application)

    container
      .register(StringSupporter.self) { resolver in
        resolver.resolveWrapper(LocalizeUtils.self)
      }
      .inObjectScope(.application)
    
    container
      .register(PlayerConfiguration.self) {
        PlayerConfigurationImpl($0.resolveWrapper(LocalStorageRepository.self).getCultureCode())
      }
    
    container
      .register(CustomerServiceProtocol.self) { resolver in
        CSAdapter(resolver.resolveWrapper(HttpClient.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CSSurveyProtocol.self) { resolver in
        CSSurveyAdapter(resolver.resolveWrapper(HttpClient.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CSHistoryProtocol.self) { resolver in
        CSHistoryAdapter(resolver.resolveWrapper(HttpClient.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CashProtocol.self) {
        CashAdapter($0.resolveWrapper(HttpClient.self))
      }
    
    container
      .register(PlayerProtocol.self) {
        PlayerAdapter(PlayerApi($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(WithdrawalProtocol.self) {
        WithdrawalAdapter(WithdrawalAPI($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(ImageProtocol.self) {
        ImageAdapter(ImageApi($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(CryptoProtocol.self) {
        CryptoAdapter(CryptoAPI($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(DepositProtocol.self) {
        DepositAdapter(DepositAPI($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(CommonProtocol.self) {
        CommonAdapter(CommonAPI($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(ArcadeProtocol.self) {
        ArcadeAdapter(ArcadeApi($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(NumberGameProtocol.self) {
        NumberGameAdapter(NumberGameApi($0.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(CasinoGameProtocol.self) {
        CasinoGameAdapter($0.resolveWrapper(HttpClient.self))
      }
    
    container
      .register(CasinoMyBetProtocol.self) { resolver in
        CasinoMyBetAdapter(.init(resolver.resolveWrapper(HttpClient.self)))
      }
    
    container.register(P2PMyBetProtocol.self) { resolver in
      P2PMyBetAdapter(.init(resolver.resolveWrapper(HttpClient.self)))
    }
    
    container.register(PromotionProtocol.self) { _ in
      PromotionAdapter()
    }
    
    container.register(DefaultProductProtocol.self) {
      DefaultProductAdapter($0.resolveWrapper(HttpClient.self))
    }
  }

  // MARK: - NumberGameModule
  
  func registerNumberGameModule() {
    container
      .register(INumberGameAppService.self) {
        ProvideModule.shared.numberGameAppService(
          playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self),
          numberGameProtocol: $0.resolveWrapper(NumberGameProtocol.self))
      }
  }
  
  // MARK: - ArcadeModule
  
  func registerArcadeModule() {
    container
      .register(IArcadeAppService.self) {
        ProvideModule.shared.arcadeAppService(
          playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self),
          arcadeProtocol: $0.resolveWrapper(ArcadeProtocol.self))
      }
  }

  // MARK: - WalletModule
  
  func registerWalletModule() {
    container
      .register(IDepositAppService.self) {
        ProvideModule.shared.depositAppService(
          depositProtocol: $0.resolveWrapper(DepositProtocol.self),
          cashProtocol: $0.resolveWrapper(CashProtocol.self),
          imageProtocol: $0.resolveWrapper(ImageProtocol.self),
          commonProtocol: $0.resolveWrapper(CommonProtocol.self),
          playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self),
          depositStringService: $0.resolveWrapper(ExternalStringService.self).deposit(),
          stringSupporter: $0.resolveWrapper(StringSupporter.self))
      }
      .inObjectScope(.locale)

    container
      .register(IWithdrawalAppService.self) { resolver in
        ProvideModule.shared.withdrawalAppService(
          playerProtocol: resolver.resolveWrapper(PlayerProtocol.self),
          withdrawalProtocol: resolver.resolveWrapper(WithdrawalProtocol.self),
          imageProtocol: resolver.resolveWrapper(ImageProtocol.self),
          cryptoProtocol: resolver.resolveWrapper(CryptoProtocol.self),
          playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self))
      }
      .inObjectScope(.locale)
  }
  
  // MARK: - CustomerServiceModule
  
  func registerCustomerServiceModule() {
    container
      .register(CSEventService.self) { resolver in
        CSEventServiceAdapter(
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CustomerServiceProtocol.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(ICustomerServiceAppService.self) { resolver in
        ProvideModule.shared.csAppService(
          playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
          customerServiceProtocol: resolver.resolveWrapper(CustomerServiceProtocol.self),
          csSurveyProtocol: resolver.resolveWrapper(CSSurveyProtocol.self),
          csHistoryProtocol: resolver.resolveWrapper(CSHistoryProtocol.self),
          csEventService: resolver.resolveWrapper(CSEventService.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(IChatAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
    
    container
      .register(ISurveyAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
    
    container
      .register(IChatHistoryAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
  }
  
  // MARK: - CasinoModule
  
  func registerCasinoModule() {
    container
      .register(ICasinoAppService.self) { resolver in
        ProvideModule.shared.casinoAppService(
          casinoGameProtocol: resolver.resolveWrapper(CasinoGameProtocol.self),
          casinoMyBetProtocol: resolver.resolveWrapper(CasinoMyBetProtocol.self),
          promotionProtocol: resolver.resolveWrapper(PromotionProtocol.self),
          playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
          stringSupporter: resolver.resolveWrapper(StringSupporter.self),
          externalStringService: resolver.resolveWrapper(ExternalStringService.self))
      }
    
    container
      .register(ICasinoGameAppService.self) { resolver in
        resolver.resolveWrapper(ICasinoAppService.self)
      }
    
    container
      .register(ICasinoMyBetAppService.self) { resolver in
        resolver.resolveWrapper(ICasinoAppService.self)
      }
  }
  
  // MARK: - P2PModule
  
  func registerP2PModule() {
    container.register(IP2PAppService.self) { resolver in
      ProvideModule.shared.p2pAppService(
        playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
        p2pMyBetProtocol: resolver.resolveWrapper(P2PMyBetProtocol.self),
        stringSupporter: resolver.resolveWrapper(StringSupporter.self),
        externalStringService: resolver.resolveWrapper(ExternalStringService.self))
    }
  }
  
  // MARK: - TransactionModule
  
  func registerTransactionModule() {
    container.register(ITransactionAppService.self) {
      ProvideModule.shared.transactionAppService(
        playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self),
        cashProtocol: $0.resolveWrapper(CashProtocol.self),
        stringSupporter: $0.resolveWrapper(StringSupporter.self),
        transactionResource: TransactionResourceAdapter())
    }
  }
  
  // MARK: - PlayerSettingModule
  
  func registerPlayerSettingModule() {
    container.register(DefaultProductAppService.self) {
      ProvideModule.shared.defaultProductAppService(defaultProductProtocol: $0.resolveWrapper(DefaultProductProtocol.self))
    }
  }
}
