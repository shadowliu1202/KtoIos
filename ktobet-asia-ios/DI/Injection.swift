import Foundation
import SharedBu
import Swinject

final class Injection {
  static let shared = Injection()

  private(set) var container = Container()

  private init() {
    HelperKt.doInitKoin()

    registerAllDependency()
  }

  func registerAllDependency() {
    registerHttpClient()
    registerCustomServicePresenter()
    registApi()
    registRepo()
    registUsecase()
    registNavigator()
    registViewModel()
    registSingleton()

    registerSharedBuModule()
  }

  // MARK: - HttpClient
  
  func registerHttpClient() {
    container
      .register(KtoURL.self) { _ in
        PortalURL.shared
      }
      .inObjectScope(.application)

    container
      .register(KtoURL.self, name: "update") { _ in
        VersionUpdateURL.shared
      }

    container
      .register(HttpClient.self) { resolver in
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let ktoUrl = resolver.resolveWrapper(KtoURL.self)
        return HttpClient(localStorageRepo, ktoUrl)
      }
      .inObjectScope(.locale)

    container
      .register(HttpClient.self, name: "update") { resolver in
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let ktoUrl = resolver.resolveWrapper(KtoURL.self, name: "update")
        return HttpClient(localStorageRepo, ktoUrl)
      }
      .inObjectScope(.locale)
  }

  // MARK: - CustomerServicePresenter
  
  func registerCustomServicePresenter() {
    container
      .register(CustomServicePresenter.self) { resolver in
        let csViewModel = resolver.resolveWrapper(CustomerServiceViewModel.self)
        let surveyViewModel = resolver.resolveWrapper(SurveyViewModel.self)
        return CustomServicePresenter(csViewModel, surveyViewModel)
      }
      .inObjectScope(.application)
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
      .register(OldWithdrawalAPI.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return OldWithdrawalAPI(httpClient)
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
    container
      .register(TransactionLogApi.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return TransactionLogApi(httpClient)
      }
    
    container
      .register(ChatHistoryAPI.self) { resolver in
        ChatHistoryAPI(resolver.resolveWrapper(HttpClient.self))
      }
    
    container
      .register(CustomServiceAPI.self) { resolver in
        .init(resolver.resolveWrapper(HttpClient.self))
      }
    
    container
      .register(SurveyAPI.self) { resolver in
        .init(resolver.resolveWrapper(HttpClient.self))
      }
  }

  // MARK: - Repo
  
  func registRepo() {
    container
      .register(PlayerRepository.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        let player = resolver.resolveWrapper(PlayerApi.self)
        let portal = resolver.resolveWrapper(PortalApi.self)
        let settingStore = resolver.resolveWrapper(SettingStore.self)
        let localStorageRepositoryImpl = resolver.resolveWrapper(LocalStorageRepository.self)
        let memoryCacheImpl = resolver.resolveWrapper(MemoryCacheImpl.self)

        return PlayerRepositoryImpl(
          httpClient,
          player,
          portal,
          settingStore,
          localStorageRepositoryImpl,
          memoryCacheImpl)
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
        let api = resolver.resolveWrapper(AuthenticationApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return IAuthRepositoryImpl(api, httpClient)
      }

    container
      .register(SystemRepository.self) { resolver in
        let api = resolver.resolveWrapper(PortalApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return SystemRepositoryImpl(api, httpClient: httpClient)
      }

    container
      .register(ResetPasswordRepository.self) { resolver in
        let api = resolver.resolveWrapper(AuthenticationApi.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return IAuthRepositoryImpl(api, httpClient)
      }

    container
      .register(PlayerConfiguration.self) { _ in
        PlayerConfigurationImpl()
      }
      .inObjectScope(.locale)

    container
      .register(LocalStorageRepository.self) {
        LocalStorageRepositoryImpl(
          playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self))
      }
      .inObjectScope(.locale)

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
      .register(WithdrawalRepository.self) { resolver in
        let imageApi = resolver.resolveWrapper(ImageApi.self)
        let oldWithdrawalAPI = resolver.resolveWrapper(OldWithdrawalAPI.self)
        let repoBank = resolver.resolveWrapper(BankRepository.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return WithdrawalRepositoryImpl(
          imageApi: imageApi,
          oldWithdrawalAPI: oldWithdrawalAPI,
          bankRepository: repoBank,
          localStorageRepo: localStorageRepo,
          httpClient: httpClient)
      }

    container
      .register(CasinoRecordRepository.self) { resolver in
        let casinoApi = resolver.resolveWrapper(CasinoApi.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)

        return CasinoRecordRepositoryImpl(
          casinoApi,
          localStorageRepo: localStorageRepo)
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
      .register(SlotRecordRepository.self) { resolver in
        let slotApi = resolver.resolveWrapper(SlotApi.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return SlotRecordRepositoryImpl(
          slotApi,
          localStorageRepo: localStorageRepo,
          httpClient: httpClient)
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
      .register(P2PRecordRepository.self) { resolver in
        let p2pApi = resolver.resolveWrapper(P2PApi.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return P2PRecordRepositoryImpl(
          p2pApi,
          localStorageRepo: localStorageRepo,
          httpClient: httpClient)
      }

    container
      .register(ArcadeRecordRepository.self) { resolver in
        let arcadeApi = resolver.resolveWrapper(ArcadeApi.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        let httpClient = resolver.resolveWrapper(HttpClient.self)

        return ArcadeRecordRepositoryImpl(
          arcadeApi,
          localStorageRepo: localStorageRepo,
          httpClient: httpClient)
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
      .register(TransactionLogRepository.self) { resolver in
        let promotionApi = resolver.resolveWrapper(TransactionLogApi.self)
        return TransactionLogRepositoryImpl(promotionApi)
      }

    container
      .register(AccountPatternGenerator.self) { resolver in
        let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
        return AccountPatternGeneratorFactory.create(repoLocalStorage.getSupportLocale())
      }

    container
      .register(LocalizationRepository.self) { resolver in
        let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
        let portalApi = resolver.resolveWrapper(PortalApi.self)
        return LocalizationRepositoryImpl(repoLocalStorage, portalApi)
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
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return SignalRepositoryImpl(httpClient: httpClient)
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
      .register(ConfigurationUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(PlayerRepository.self)
        let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
        return ConfigurationUseCaseImpl(repo, repoLocalStorage)
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
      .register(PlayerDataUseCase.self) { resolver in
        let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
        let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)

        return PlayerDataUseCaseImpl(repoPlayer, repoLocal)
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
      .register(WithdrawalUseCase.self) { resolver in
        let repoWithdrawal = resolver.resolveWrapper(WithdrawalRepository.self)
        let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
        return WithdrawalUseCaseImpl(repoWithdrawal, repoLocal)
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
      .register(CasinoUseCase.self) { resolver in
        CasinoUseCaseImpl(
          casinoRepository: resolver.resolveWrapper(CasinoRepository.self),
          localStorageRepo: resolver.resolveWrapper(LocalStorageRepository.self),
          promotionRepository: resolver.resolveWrapper(PromotionRepository.self))
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
      .register(TransactionLogUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(TransactionLogRepository.self)
        let player = resolver.resolveWrapper(PlayerRepository.self)
        return TransactionLogUseCaseImpl(repo, player)
      }

    container
      .register(LocalizationPolicyUseCase.self) { resolver in
        let repoLocalization = resolver.resolveWrapper(LocalizationRepository.self)
        return LocalizationPolicyUseCaseImpl(repoLocalization)
      }

    container
      .register(AppVersionUpdateUseCase.self) { resolver in
        let repo = resolver.resolveWrapper(AppUpdateRepository.self)
        let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
        return AppVersionUpdateUseCaseImpl(repo, repoLocalStorage)
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
      .inObjectScope(.depositFlow)

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
          resolver.resolveWrapper(LocalStorageRepository.self),
          resolver.resolveWrapper(ActivityIndicator.self, name: "CheckingIsLogged"))
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
      .register(DefaultProductViewModel.self) { resolver in
        let usecase = resolver.resolveWrapper(ConfigurationUseCase.self)
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        return DefaultProductViewModel(usecase, systemUseCase)
      }

    container
      .register(ResetPasswordViewModel.self) { resolver in
        let usecaseAuthentication = resolver.resolveWrapper(ResetPasswordUseCase.self)
        let systemUseCase = resolver.resolveWrapper(ISystemStatusUseCase.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        return ResetPasswordViewModel(usecaseAuthentication, systemUseCase, localStorageRepo)
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
      .register(PromotionHistoryViewModel.self) { resolver in
        .init(
          promotionUseCase: resolver.resolveWrapper(PromotionUseCase.self),
          localRepo: resolver.resolveWrapper(LocalStorageRepository.self))
      }

    container
      .register(CustomerServiceViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IChatAppService.self),
          resolver.resolveWrapper(Loading.self))
      }
      .inObjectScope(.locale)

    container
      .register(SurveyViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(ISurveyAppService.self),
          resolver.resolveWrapper(AuthenticationUseCase.self))
      }

    container
      .register(CustomerServiceMainViewModel.self) { resolver in
        .init(resolver.resolveWrapper(IChatAppService.self))
      }

    container
      .register(CustomerServiceHistoryViewModel.self) { resolver in
        CustomerServiceHistoryViewModel(resolver.resolveWrapper(IChatHistoryAppService.self))
      }

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
      .register(ConfigurationViewModel.self) { resolver in
        let useCaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
        let localStorageRepo = resolver.resolve(LocalStorageRepository.self)!
        return ConfigurationViewModel(useCaseConfiguration, localStorageRepo)
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
      .register(LoginViewModel.self) { resolver in
        let authenticationUseCase = resolver.resolveWrapper(AuthenticationUseCase.self)
        let configurationUseCase = resolver.resolveWrapper(ConfigurationUseCase.self)
        let navigationViewModel = resolver.resolveWrapper(NavigationViewModel.self)
        let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
        return LoginViewModel(authenticationUseCase, configurationUseCase, navigationViewModel, localStorageRepo)
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
      .register(OfflinePaymentViewModel.self) { resolver in
        OfflinePaymentViewModel(
          depositService: resolver.resolveWrapper(IDepositAppService.self),
          playerUseCase: resolver.resolveWrapper(PlayerDataUseCase.self),
          localStorageRepo: resolver.resolveWrapper(LocalStorageRepository.self))
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

    container.register(WithdrawalAddFiatBankCardViewModel.self) { resolver in
      WithdrawalAddFiatBankCardViewModel(
        resolver.resolveWrapper(LocalStorageRepository.self),
        resolver.resolveWrapper(AuthenticationUseCase.self),
        resolver.resolveWrapper(BankUseCase.self),
        resolver.resolveWrapper(PlayerDataUseCase.self),
        resolver.resolveWrapper(AccountPatternGenerator.self),
        resolver.resolveWrapper(IWithdrawalAppService.self))
    }

    container
      .register(WithdrawalCryptoRequestStep1ViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(LocalStorageRepository.self))
      }

    container
      .register(WithdrawalCryptoRequestStep2ViewModel.self) { resolver in
        .init(
          resolver.resolveWrapper(IWithdrawalAppService.self),
          resolver.resolveWrapper(PlayerConfiguration.self))
      }
  }

  // MARK: - Singleton
  
  func registSingleton() {
    container
      .register(LocalizeUtils.self) { resolver in
        LocalizeUtils(localStorageRepo: resolver.resolveWrapper(LocalStorageRepository.self))
      }
      .inObjectScope(.application)

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
  }

  // MARK: - SharedBu
  
  func registerSharedBuModule() {
    registerExternalProtocol()
    registerProductModule()
    registerWalletModule()
    registerCustomerServiceModule()
    registerCasinoModule()
    registerPromotionModule()
    registerP2PModule()
  }

  // MARK: - ExternalProtocol
  
  func registerExternalProtocol() {
    container
      .register(PlayerConfiguration.self) { _ in
        PlayerConfigurationImpl()
      }
      .inObjectScope(.locale)

    container
      .register(ExternalProtocolService.self) { resolver in
        let httpClient = resolver.resolveWrapper(HttpClient.self)
        return ExternalProtocolServiceFactory(httpClient)
      }
      .inObjectScope(.locale)

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
      .register(ApplicationFactory.self) { resolver in
        let playerConfiguration = resolver.resolveWrapper(PlayerConfiguration.self)
        let protocolFactory = resolver.resolveWrapper(ExternalProtocolService.self)
        let stringServiceFactory = resolver.resolveWrapper(ExternalStringService.self)
        let localize = resolver.resolveWrapper(StringSupporter.self)

        return ApplicationFactory(
          playerConfiguration: playerConfiguration,
          externalProtocolService: protocolFactory,
          stringServiceFactory: stringServiceFactory,
          stringSupporter: localize)
      }
      .inObjectScope(.locale)
  }

  // MARK: - ProductModule
  
  func registerProductModule() {
    container
      .register(INumberGameAppService.self) { resolver in
        resolver.resolveWrapper(ApplicationFactory.self)
          .numberGame()
      }

    container
      .register(IArcadeAppService.self) { resolver in
        resolver.resolveWrapper(ApplicationFactory.self)
          .arcade()
      }
  }

  // MARK: - WalletModule
  
  func registerWalletModule() {
    let walletModule = WalletModule()

    container
      .register(IDepositAppService.self) { resolver in
        resolver.resolveWrapper(ApplicationFactory.self)
          .deposit()
      }

    container
      .register(IWithdrawalAppService.self) { resolver in
        walletModule
          .getWithdrawalAppService(
            playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
            withdrawalProtocol: resolver.resolveWrapper(ExternalProtocolService.self).getWithdrawal(),
            imageProtocol: resolver.resolveWrapper(ExternalProtocolService.self).getImage(),
            cryptoProtocol: resolver.resolveWrapper(ExternalProtocolService.self).getCrypto(),
            playerProtocol: resolver.resolveWrapper(ExternalProtocolService.self).getPlayer())
      }
      .inObjectScope(.withdrawalFlow)
  }
  
  // MARK: - CustomerServiceModule
  
  func registerCustomerServiceModule() {
    container
      .register(CustomerServiceProtocol.self) { resolver in
        CSAdapter(resolver.resolveWrapper(CustomServiceAPI.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CSSurveyProtocol.self) { resolver in
        CSSurveyAdapter(resolver.resolveWrapper(SurveyAPI.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CSHistoryProtocol.self) { resolver in
        CSHistoryAdapter(resolver.resolveWrapper(ChatHistoryAPI.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(CSEventService.self) { resolver in
        CSEventServiceAdapter(
          resolver.resolveWrapper(HttpClient.self),
          resolver.resolveWrapper(CustomerServiceProtocol.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(ICustomerServiceAppService.self) { resolver in
        CustomerServiceModule().getCSAppService(
          customerServiceProtocol: resolver.resolveWrapper(CustomerServiceProtocol.self),
          cSSurveyProtocol: resolver.resolveWrapper(CSSurveyProtocol.self),
          cSHistoryProtocol: resolver.resolveWrapper(CSHistoryProtocol.self),
          cSEventService: resolver.resolveWrapper(CSEventService.self),
          playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self))
      }
      .inObjectScope(.locale)
    
    container
      .register(IChatAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
      .inObjectScope(.locale)
    
    container
      .register(ISurveyAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
      .inObjectScope(.locale)
    
    container
      .register(IChatHistoryAppService.self) { resolver in
        resolver.resolveWrapper(ICustomerServiceAppService.self)
      }
      .inObjectScope(.locale)
  }
  
  // MARK: - CasinoModule
  
  func registerCasinoModule() {
    container
      .register(CasinoGameProtocol.self) { resolver in
        CasinoGameAdapter(.init(resolver.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(CasinoMyBetProtocol.self) { resolver in
        CasinoMyBetAdapter(.init(resolver.resolveWrapper(HttpClient.self)))
      }
    
    container
      .register(ICasinoAppService.self) { resolver in
        CasinoModule().getCasinoAppService(
          casinoGameProtocol: resolver.resolveWrapper(CasinoGameProtocol.self),
          casinoMyBetProtocol: resolver.resolveWrapper(CasinoMyBetProtocol.self),
          promotionProtocol: resolver.resolveWrapper(PromotionProtocol.self),
          playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
          stringServiceFactory: resolver.resolveWrapper(ExternalStringService.self),
          stringSupporter: resolver.resolveWrapper(StringSupporter.self))
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
  
  // MARK: - PromotionModule
  
  func registerPromotionModule() {
    container.register(PromotionProtocol.self) { _ in
      PromotionAdapter()
    }
  }
  
  // MARK: - P2PModule
  
  func registerP2PModule() {
    container.register(P2PMyBetProtocol.self) { resolver in
      P2PMyBetAdapter(.init(resolver.resolveWrapper(HttpClient.self)))
    }
    
    container.register(IP2PAppService.self) { resolver in
      P2PModule().getP2PAppService(
        p2PMyBetProtocol: resolver.resolveWrapper(P2PMyBetProtocol.self),
        playerConfiguration: resolver.resolveWrapper(PlayerConfiguration.self),
        stringSupporter: resolver.resolveWrapper(StringSupporter.self),
        externalStringService: resolver.resolveWrapper(ExternalStringService.self))
    }
  }
}
