import Foundation
import Swinject
import SharedBu

final class Injection {
    
    static let shared = Injection()
    
    private (set) var container = Container()
    
    private init() {
        registerAllDependency()
    }
    
    
    /// Only be use in unit test.
    func registerAllDependency () {
        registerHttpClient()
        registerCustomServicePresenter()
        registFactory()
        registApi()
        registRepo()
        registUsecase()
        registNavigator()
        registViewModel()
        registSingleton()
    }
    
    func registerHttpClient() {
        container
            .register(KtoURL.self) { _ in
                return PortalURL()
            }
            .inObjectScope(.application)
        
        container
            .register(KtoURL.self, name: "update") { _ in
                return VersionUpdateURL()
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
    
    func registerCustomServicePresenter() {
        container
            .register(CustomServicePresenter.self) { resolver in
                let csViewModel = resolver.resolveWrapper(CustomerServiceViewModel.self)
                let surveyViewModel = resolver.resolveWrapper(SurveyViewModel.self)
                return CustomServicePresenter(csViewModel, surveyViewModel)
            }
            .inObjectScope(.application)
    }
    
    func registFactory() {
        container
            .register(ExternalProtocolService.self) { resolver in
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                return NetworkFactory(httpClient)
            }
            .inObjectScope(.locale)
        
        container
            .register(ExternalStringService.self) { _ in
                return DepositStringServiceFactory()
            }
            .inObjectScope(.application)
        
        container
            .register(StringSupporter.self) { (resolver)  in
                return resolver.resolveWrapper(LocalizeUtils.self)
            }
            .inObjectScope(.application)
        
        container
            .register(ApplicationFactory.self) { resolver in
                let local = resolver.resolveWrapper(PlayerConfiguration.self)
                let network = resolver.resolveWrapper(ExternalProtocolService.self)
                let stringService = resolver.resolveWrapper(ExternalStringService.self)
                let localize = resolver.resolveWrapper(StringSupporter.self)
                
                return ApplicationFactory(
                    playerConfiguration: local,
                    externalProtocolService: network,
                    stringServiceFactory: stringService,
                    stringSupporter: localize
                )
            }
            .inObjectScope(.locale)
    }
    
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
            .register(CustomServiceApi.self) { resolver in
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                return CustomServiceApi(httpClient)
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
            .register(CPSApi.self) { resolver in
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                return CPSApi(httpClient)
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
    }
    
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
                    memoryCacheImpl
                )
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
            .register(CustomServiceRepository.self) { resolver in
                let csApi = resolver.resolveWrapper(CustomServiceApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                let local = resolver.resolveWrapper(LocalStorageRepository.self)
                return CustomServiceRepositoryImpl(csApi, httpClient, local)
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
            .register(SystemSignalRepository.self) { resolver in
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                return SystemSignalRepositoryImpl(httpClient)
            }
        
        container
                    .register(PlayerConfiguration.self) { _ in
                        return PlayerConfigurationImpl()
                    }
                    .inObjectScope(.locale)
                container
                    .register(LocalStorageRepository.self) {
                        LocalStorageRepositoryImpl(
                            playerConfiguration: $0.resolveWrapper(PlayerConfiguration.self)
                        )
                    }
                    .inObjectScope(.locale)
        
        container
            .register(SettingStore.self) { _ in
                return SettingStore()
            }
        container
            .register(DepositRepository.self) { resolver in
                let bankApi = resolver.resolveWrapper(BankApi.self)
                return DepositRepositoryImpl(bankApi)
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
                let bankApi = resolver.resolveWrapper(BankApi.self)
                let imageApi = resolver.resolveWrapper(ImageApi.self)
                let cpsApi = resolver.resolveWrapper(CPSApi.self)
                let repoBank = resolver.resolveWrapper(BankRepository.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return WithdrawalRepositoryImpl(
                    bankApi,
                    imageApi: imageApi,
                    cpsApi: cpsApi,
                    bankRepository: repoBank,
                    localStorageRepo: localStorageRepo,
                    httpClient: httpClient
                )
            }
        
        container
            .register(CasinoRecordRepository.self) { resolver in
                let casinoApi = resolver.resolveWrapper(CasinoApi.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                
                return CasinoRecordRepositoryImpl(
                    casinoApi,
                    localStorageRepo: localStorageRepo
                )
            }
        
        container
            .register(CasinoRepository.self) { resolver in
                let casinoApi = resolver.resolveWrapper(CasinoApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return CasinoRepositoryImpl(
                    casinoApi,
                    httpClient: httpClient
                )
            }
        
        container
            .register(SlotRepository.self) { resolver in
                let slotApi = resolver.resolveWrapper(SlotApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return SlotRepositoryImpl(
                    slotApi,
                    httpClient: httpClient
                )
            }
        
        container
            .register(SlotRecordRepository.self) { resolver in
                let slotApi = resolver.resolveWrapper(SlotApi.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return SlotRecordRepositoryImpl(
                    slotApi,
                    localStorageRepo: localStorageRepo,
                    httpClient: httpClient
                )
            }
        
        container
            .register(NumberGameRepository.self) { resolver in
                let numberGameApi = resolver.resolveWrapper(NumberGameApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return NumberGameRepositoryImpl(
                    numberGameApi,
                    httpClient: httpClient
                )
            }
        
        container
            .register(NumberGameRecordRepository.self) { resolver in
                let numberGameApi = resolver.resolveWrapper(NumberGameApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return NumberGameRecordRepositoryImpl(
                    numberGameApi,
                    httpClient: httpClient
                )
            }
        
        container
            .register(P2PRepository.self) { resolver in
                let p2pApi = resolver.resolveWrapper(P2PApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return P2PRepositoryImpl(
                    p2pApi,
                    httpClient: httpClient
                )
            }
        
        container
            .register(P2PRecordRepository.self) { resolver in
                let p2pApi = resolver.resolveWrapper(P2PApi.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return P2PRecordRepositoryImpl(
                    p2pApi,
                    localStorageRepo: localStorageRepo,
                    httpClient: httpClient
                )
            }
        
        container
            .register(ArcadeRecordRepository.self) { resolver in
                let arcadeApi = resolver.resolveWrapper(ArcadeApi.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return ArcadeRecordRepositoryImpl(
                    arcadeApi,
                    localStorageRepo: localStorageRepo,
                    httpClient: httpClient
                )
            }
        
        container
            .register(ArcadeRepository.self) { resolver in
                let arcadeApi = resolver.resolveWrapper(ArcadeApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                
                return ArcadeRepositoryImpl(
                    arcadeApi,
                    httpClient: httpClient
                )
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
            .register(SurveyInfraService.self) { resolver in
                let csApi = resolver.resolveWrapper(CustomServiceApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                let local = resolver.resolveWrapper(LocalStorageRepository.self)
                
                return CustomServiceRepositoryImpl(csApi, httpClient, local)
            }
        
        container
            .register(CustomerInfraService.self) { resolver in
                let csApi = resolver.resolveWrapper(CustomServiceApi.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                let local = resolver.resolveWrapper(LocalStorageRepository.self)
                
                return CustomServiceRepositoryImpl(csApi, httpClient, local)
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
                return MemoryCacheImpl()
            }
            .inObjectScope(.locale)
    }
    
    func registUsecase(){
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
                    repoAuth,
                    repoPlayer,
                    repoLocalStorage,
                    settingStore
                )
            }
        
        container
            .register(GetSystemStatusUseCase.self) { resolver in
                let repoSystem = resolver.resolveWrapper(SystemRepository.self)
                return GetSystemStatusUseCaseImpl(repoSystem)
            }
        
        container
            .register(ResetPasswordUseCase.self) { resolver in
                let repoSystem = resolver.resolveWrapper(ResetPasswordRepository.self)
                let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
                
                return ResetPasswordUseCaseImpl(
                    repoSystem,
                    localRepository: repoLocal
                )
            }
        
        container
            .register(SystemSignalRUseCase.self) { resolver in
                let repoSystem = resolver.resolveWrapper(SystemSignalRepository.self)
                return SystemSignalRUseCaseImpl(repoSystem)
            }
        
        container
            .register(PlayerDataUseCase.self) { resolver in
                let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
                let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
                let settingStore = resolver.resolveWrapper(SettingStore.self)
                
                return PlayerDataUseCaseImpl(
                    repoPlayer,
                    localRepository: repoLocal,
                    settingStore: settingStore
                )
            }
        
        container
            .register(DepositUseCase.self) { resolver in
                let repoDeposit = resolver.resolveWrapper(DepositRepository.self)
                return DepositUseCaseImpl(repoDeposit)
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
                let repo = resolver.resolveWrapper(CasinoRepository.self)
                let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
                return CasinoUseCaseImpl(repo, repoLocal)
            }
        
        container
            .register(SlotUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(SlotRepository.self)
                let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
                return SlotUseCaseImpl(repo, repoLocal)
            }
        
        container
            .register(SlotRecordUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(SlotRecordRepository.self)
                let repoPlayer = resolver.resolveWrapper(PlayerRepository.self)
                return SlotRecordUseCaseImpl(repo, playerRepository: repoPlayer)
            }
        
        container
            .register(NumberGameUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(NumberGameRepository.self)
                let repoLocal = resolver.resolveWrapper(LocalStorageRepository.self)
                return NumberGameUseCasaImp(repo, repoLocal)
            }
        
        container
            .register(NumberGameRecordUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(NumberGameRecordRepository.self)
                return NumberGameRecordUseCaseImpl(numberGameRecordRepository: repo)
            }
        
        container
            .register(P2PUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(P2PRepository.self)
                return P2PUseCaseImpl(repo)
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
                let repo = resolver.resolveWrapper(ArcadeRepository.self)
                return ArcadeUseCaseImpl(repo)
            }
        
        container
            .register(PromotionUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(PromotionRepository.self)
                let player = resolver.resolveWrapper(PlayerRepository.self)
                
                return PromotionUseCaseImpl(
                    repo,
                    playerRepository: player
                )
            }
        
        container
            .register(TransactionLogUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(TransactionLogRepository.self)
                let player = resolver.resolveWrapper(PlayerRepository.self)
                return TransactionLogUseCaseImpl(repo, player)
            }
        
        container
            .register(CustomerServiceUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(CustomServiceRepository.self)
                let infra = resolver.resolveWrapper(CustomerInfraService.self)
                let surver = resolver.resolveWrapper(SurveyInfraService.self)
                return CustomerServiceUseCaseImpl(
                    repo,
                    customerInfraService: infra,
                    surveyInfraService: surver
                )
            }
        
        container
            .register(CustomerServiceSurveyUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(CustomServiceRepository.self)
                let surver = resolver.resolveWrapper(SurveyInfraService.self)
                
                return CustomerServiceSurveyUseCaseImpl(
                    repo,
                    surveyInfraService: surver
                )
            }
        
        container
            .register(ChatRoomHistoryUseCase.self) { resolver in
                let repo = resolver.resolveWrapper(CustomServiceRepository.self)
                let infra = resolver.resolveWrapper(CustomerInfraService.self)
                let surver = resolver.resolveWrapper(SurveyInfraService.self)
                return CustomerServiceUseCaseImpl(
                    repo,
                    customerInfraService: infra,
                    surveyInfraService: surver
                )
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
    
    func registNavigator() {
        container
            .register(DepositNavigator.self) { _ in
                return DepositNavigatorImpl()
            }
    }
    
    func registViewModel(){
        container
            .register(CryptoDepositViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let deposit = applicationFactory.deposit()
                let navigator = resolver.resolveWrapper(DepositNavigator.self)
                return CryptoDepositViewModel(depositService: deposit, navigator: navigator)
            }
        
        container
            .register(ThirdPartyDepositViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let deposit = applicationFactory.deposit()
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let navigator = resolver.resolveWrapper(DepositNavigator.self)
                let httpClient = resolver.resolveWrapper(HttpClient.self)
                return ThirdPartyDepositViewModel(playerUseCase: playerUseCase, depositService: deposit, navigator: navigator, httpClient: httpClient)
            }
        
        container
            .register(OfflineViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let deposit = applicationFactory.deposit()
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let pattern = resolver.resolveWrapper(AccountPatternGenerator.self)
                let bankUseCase = resolver.resolveWrapper(BankUseCase.self)
                let navigator = resolver.resolveWrapper(DepositNavigator.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                return OfflineViewModel(deposit, playerUseCase: playerUseCase, accountPatternGenerator: pattern, bankUseCase: bankUseCase, navigator: navigator, localStorageRepo: localStorageRepo)
            }
            .inObjectScope(.depositFlow)
        
        container
            .register(DepositViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let deposit = applicationFactory.deposit()
                let depositUseCase = resolver.resolveWrapper(DepositUseCase.self)
                
                return .init(
                    depositService: deposit,
                    depositUseCase: depositUseCase
                )
            }
        
        container
            .register(DepositLogViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let deposit = applicationFactory.deposit()
                return .init(deposit)
            }
        
        container
            .register(NotificationViewModel.self) { resolver in
                let useCase = resolver.resolveWrapper(NotificationUseCase.self)
                let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                return NotificationViewModel(useCase: useCase, configurationUseCase: usecaseConfiguration, systemStatusUseCase: systemUseCase)
            }
        
        container
            .register(NavigationViewModel.self) { (resolver)  in
                let usecaseAuth = resolver.resolveWrapper(AuthenticationUseCase.self)
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let localizationUseCase = resolver.resolveWrapper(LocalizationPolicyUseCase.self)
                let getSystemStatusUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                return NavigationViewModel(usecaseAuth, playerUseCase, localizationUseCase, getSystemStatusUseCase, localStorageRepo)
            }
        
        container
            .register(LoginViewModel.self) { resolver in
                let usecaseAuthentication = resolver.resolveWrapper(AuthenticationUseCase.self)
                let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
                return LoginViewModel(usecaseAuthentication, usecaseConfiguration)
            }
        
        container
            .register(SignupUserInfoViewModel.self){ resolver in
                let registerUseCase = resolver.resolveWrapper(RegisterUseCase.self)
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
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
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                return DefaultProductViewModel(usecase, systemUseCase)
            }
        
        container
            .register(ResetPasswordViewModel.self) { resolver in
                let usecaseAuthentication = resolver.resolveWrapper(ResetPasswordUseCase.self)
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                return ResetPasswordViewModel(usecaseAuthentication, systemUseCase, localStorageRepo)
            }
        
        container
            .register(SystemViewModel.self) { resolver in
                let systemSignalRUseCase = resolver.resolveWrapper(SystemSignalRUseCase.self)
                return SystemViewModel(systemUseCase: systemSignalRUseCase)
            }
        
        container
            .register(ServiceStatusViewModel.self) { resolver in
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                return ServiceStatusViewModel(systemStatusUseCase: systemUseCase, localStorageRepo: localStorageRepo)
            }
        
        container
            .register(PlayerViewModel.self) { resolver in
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let authUseCase = resolver.resolveWrapper(AuthenticationUseCase.self)
                return PlayerViewModel(playerUseCase: playerUseCase, authUseCase: authUseCase)
            }
        
        container
            .register(UploadPhotoViewModel.self) { resolver in
                let imageUseCase = resolver.resolveWrapper(UploadImageUseCase.self)
                return UploadPhotoViewModel(imageUseCase: imageUseCase)
            }
        
        container
            .register(WithdrawalViewModel.self) { resolver in
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
                return WithdrawalViewModel(withdrawalUseCase: withdrawalUseCase, localStorageRepository: repoLocalStorage)
            }
        
        container
            .register(ManageCryptoBankCardViewModel.self) { resolver in
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                return ManageCryptoBankCardViewModel(withdrawalUseCase: withdrawalUseCase)
            }
        
        container
            .register(CryptoViewModel.self) { resolver in
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                let depositUseCase = resolver.resolveWrapper(DepositUseCase.self)
                return CryptoViewModel(withdrawalUseCase: withdrawalUseCase, depositUseCase: depositUseCase)
            }
        
        container
            .register(AddBankViewModel.self) { resolver in
                return AddBankViewModel(resolver.resolveWrapper(LocalStorageRepository.self),
                                        resolver.resolveWrapper(AuthenticationUseCase.self),
                                        resolver.resolveWrapper(BankUseCase.self),
                                        resolver.resolveWrapper(WithdrawalUseCase.self),
                                        resolver.resolveWrapper(PlayerDataUseCase.self),
                                        resolver.resolveWrapper(AccountPatternGenerator.self))
            }
        
        container
            .register(WithdrawlLandingViewModel.self) { resolver in
                return WithdrawlLandingViewModel(resolver.resolveWrapper(WithdrawalUseCase.self))
            }
        
        container
            .register(WithdrawalRequestViewModel.self) { resolver in
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                return WithdrawalRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerDataUseCase: playerUseCase)
            }
        
        container
            .register(WithdrawalCryptoRequestViewModel.self) { resolver in
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let repoLocalStorage = resolver.resolveWrapper(LocalStorageRepository.self)
                return WithdrawalCryptoRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerUseCase: playerUseCase, localStorageRepository: repoLocalStorage)
            }
        
        container
            .register(CasinoViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let casinoAppService = applicationFactory.casino()
                return CasinoViewModel(casinoRecordUseCase: resolver.resolveWrapper(CasinoRecordUseCase.self), casinoUseCase: resolver.resolveWrapper(CasinoUseCase.self), memoryCache: resolver.resolveWrapper(MemoryCacheImpl.self), casinoAppService: casinoAppService)
            }
        
        container
            .register(SlotViewModel.self) { resolver in
                return SlotViewModel(slotUseCase: resolver.resolveWrapper(SlotUseCase.self))
            }
        
        container
            .register(SlotBetViewModel.self) { resolver in
                return SlotBetViewModel(slotUseCase: resolver.resolveWrapper(SlotUseCase.self), slotRecordUseCase: resolver.resolveWrapper(SlotRecordUseCase.self))
            }
        
        container
            .register(NumberGameViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let numberGameService = applicationFactory.numberGame()
                return NumberGameViewModel(numberGameUseCase: resolver.resolveWrapper(NumberGameUseCase.self), memoryCache: resolver.resolveWrapper(MemoryCacheImpl.self), numberGameService: numberGameService)
            }
        
        container
            .register(NumberGameRecordViewModel.self) { resolver in
                return NumberGameRecordViewModel(numberGameRecordUseCase: resolver.resolveWrapper(NumberGameRecordUseCase.self))
            }
        
        container
            .register(CryptoVerifyViewModel.self) { resolver in
                return CryptoVerifyViewModel(playerUseCase: resolver.resolveWrapper(PlayerDataUseCase.self), withdrawalUseCase:  resolver.resolveWrapper(WithdrawalUseCase.self), systemUseCase: resolver.resolveWrapper(GetSystemStatusUseCase.self))
            }
        
        container
            .register(P2PViewModel.self) { resolver in
                return P2PViewModel(p2pUseCase: resolver.resolveWrapper(P2PUseCase.self))
            }
        
        container
            .register(P2PBetViewModel.self) { resolver in
                return P2PBetViewModel(p2pRecordUseCase: resolver.resolveWrapper(P2PRecordUseCase.self))
            }
        
        container
            .register(ArcadeRecordViewModel.self) { resolver in
                return ArcadeRecordViewModel(arcadeRecordUseCase: resolver.resolveWrapper(ArcadeRecordUseCase.self))
            }
        
        container
            .register(ArcadeViewModel.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let arcadeAppService = applicationFactory.arcade()
                return ArcadeViewModel(arcadeUseCase: resolver.resolveWrapper(ArcadeUseCase.self), memoryCache: resolver.resolveWrapper(MemoryCacheImpl.self), arcadeAppService: arcadeAppService)
            }
        
        container
            .register(PromotionViewModel.self) { resolver in
                return PromotionViewModel(promotionUseCase: resolver.resolveWrapper(PromotionUseCase.self), playerUseCase: resolver.resolveWrapper(PlayerDataUseCase.self))
            }
        
        container
            .register(PromotionHistoryViewModel.self) { resolver in
                return PromotionHistoryViewModel(promotionUseCase: resolver.resolveWrapper(PromotionUseCase.self))
            }
        
        container
            .register(TransactionLogViewModel.self) { resolver in
                return TransactionLogViewModel(transactionLogUseCase: resolver.resolveWrapper(TransactionLogUseCase.self))
            }
        
        container
            .register(CustomerServiceViewModel.self) { resolver in
                return CustomerServiceViewModel(customerServiceUseCase: resolver.resolveWrapper(CustomerServiceUseCase.self))
            }
            .inObjectScope(.locale)
        
        container
            .register(SurveyViewModel.self) { resolver in
                return SurveyViewModel(resolver.resolveWrapper(CustomerServiceSurveyUseCase.self), resolver.resolveWrapper(AuthenticationUseCase.self))
            }
        
        container
            .register(CustomerServiceHistoryViewModel.self) { resolver in
                return CustomerServiceHistoryViewModel(historyUseCase: resolver.resolveWrapper(ChatRoomHistoryUseCase.self))
            }
        
        container
            .register(TermsViewModel.self) { resolver in
                let systemUseCase = resolver.resolveWrapper(GetSystemStatusUseCase.self)
                return TermsViewModel(localizationPolicyUseCase: resolver.resolveWrapper(LocalizationPolicyUseCase.self), systemStatusUseCase: systemUseCase)
            }
            .inObjectScope(.locale)
        
        container
            .register(ModifyProfileViewModel.self) { resolver in
                let playerUseCase = resolver.resolveWrapper(PlayerDataUseCase.self)
                let usecaseConfiguration = resolver.resolveWrapper(ConfigurationUseCase.self)
                let withdrawalUseCase = resolver.resolveWrapper(WithdrawalUseCase.self)
                let pattern = resolver.resolveWrapper(AccountPatternGenerator.self)
                return ModifyProfileViewModel(playerUseCase, usecaseConfiguration, withdrawalUseCase, pattern)
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
                let appUpdateUseCase = resolver.resolveWrapper(AppVersionUpdateUseCase.self)
                return AppSynchronizeViewModel(appUpdateUseCase: appUpdateUseCase)
            }
            .inObjectScope(.application)
        
        container
            .register(StarMergerViewModelImpl.self) { resolver in
                let applicationFactory = resolver.resolveWrapper(ApplicationFactory.self)
                let depositService = applicationFactory.deposit()
                return StarMergerViewModelImpl(depositService: depositService)
            }
        
        container
            .register(NewLoginViewModel.self) { resolver in
                let authenticationUseCase = resolver.resolveWrapper(AuthenticationUseCase.self)
                let configurationUseCase = resolver.resolveWrapper(ConfigurationUseCase.self)
                let navigationViewModel = resolver.resolveWrapper(NavigationViewModel.self)
                let localStorageRepo = resolver.resolveWrapper(LocalStorageRepository.self)
                return NewLoginViewModel(authenticationUseCase, configurationUseCase, navigationViewModel, localStorageRepo)
            }
        
        container
            .register(CryptoGuideVNDViewModelImpl.self) { (resolver) in
                let localizationUseCase = resolver.resolveWrapper(LocalizationPolicyUseCase.self)
                return CryptoGuideVNDViewModelImpl(localizationPolicyUseCase: localizationUseCase)
            }
    }
    
    func registSingleton() {
        container
            .register(LocalizeUtils.self) { resolver in
                return LocalizeUtils(localStorageRepo: resolver.resolveWrapper(LocalStorageRepository.self))
            }
            .inObjectScope(.application)
        
        container
            .register(AlertProtocol.self) { _ in
                return Alert.shared
            }
            .inObjectScope(.application)
    }
}
