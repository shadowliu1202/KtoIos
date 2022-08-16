//
//  DIContainer.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/22.
//

import Foundation
import Swinject
import SharedBu

public let DI = DIContainer.share.container

class DIContainer {
    
    static let share = DIContainer()
    let container = Container()
    
    private init() {
        registerPlayerConfig()
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
    
    func registerPlayerConfig() {
        container.register(PlayerLocaleConfiguration.self) { _ in
            return LocalStorageRepositoryImpl()
        }.inObjectScope(.lobby)
    }
    func registerHttpClient() {
        container.register(KtoURL.self) { resolver in
            return KtoURL(playConfig: resolver.resolve(PlayerLocaleConfiguration.self)!)
        }.inObjectScope(.lobby)
        container.register(HttpClient.self) { resolver in
            return HttpClient(ktoUrl: resolver.resolve(KtoURL.self)!)
        }.inObjectScope(.lobby)
    }
    func registerCustomServicePresenter() {
        container.register(CustomServicePresenter.self) { resolver in
            let csViewModel = resolver.resolve(CustomerServiceViewModel.self)!
            let surveyViewModel = resolver.resolve(SurveyViewModel.self)!
            return CustomServicePresenter(csViewModel: csViewModel, surveyViewModel: surveyViewModel)
        }.inObjectScope(.lobby)
    }
    func registFactory() {
        container.register(PlayerConfiguration.self) { _ in
            return LocalStorageRepositoryImpl()
        }.inObjectScope(.lobby)
        
        container.register(ExternalProtocolService.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return NetworkFactory(httpClient)
        }.inObjectScope(.lobby)
        
        container.register(ExternalStringService.self) { _ in
            return DepositStringServiceFactory()
        }.inObjectScope(.application)
        
        container.register(StringSupporter.self) { (resolver)  in
            return resolver.resolve(LocalizeUtils.self)!
        }.inObjectScope(.application)
        
        container.register(ApplicationFactory.self) { resolver in
            let local = resolver.resolve(PlayerConfiguration.self)!
            let network = resolver.resolve(ExternalProtocolService.self)!
            let stringService = resolver.resolve(ExternalStringService.self)!
            let localize = resolver.resolve(StringSupporter.self)!
            return ApplicationFactory(playerConfiguration: local,
                                      externalProtocolService: network,
                                      stringServiceFactory: stringService,
                                      stringSupporter: localize)
        }.inObjectScope(.lobby)
    }
    
    func registApi() {
        container.register(NotificationApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return NotificationApi(httpClient)
        }
        container.register(AuthenticationApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return AuthenticationApi(httpClient)
        }
        container.register(PlayerApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return PlayerApi(httpClient)
        }
        container.register(PortalApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return PortalApi(httpClient)
        }
        container.register(GameApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return GameApi(httpClient)
        }
        container.register(CustomServiceApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return CustomServiceApi(httpClient)
        }
        container.register(BankApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return BankApi(httpClient)
        }
        container.register(ImageApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return ImageApi(httpClient)
        }
        container.register(CasinoApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return CasinoApi(httpClient)
        }
        container.register(SlotApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return SlotApi(httpClient)
        }
        container.register(NumberGameApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return NumberGameApi(httpClient)
        }
        container.register(CPSApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return CPSApi(httpClient)
        }
        container.register(P2PApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return P2PApi(httpClient)
        }
        container.register(ArcadeApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return ArcadeApi(httpClient)
        }
        container.register(PromotionApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return PromotionApi(httpClient)
        }
        container.register(TransactionLogApi.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return TransactionLogApi(httpClient)
        }
    }
    
    func registRepo(){
        container.register(PlayerRepository.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            let player = resolver.resolve(PlayerApi.self)!
            let portal = resolver.resolve(PortalApi.self)!
            let settingStore = resolver.resolve(SettingStore.self)!
            let localStorageRepositoryImpl = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return PlayerRepositoryImpl(httpClient, player, portal, settingStore, localStorageRepositoryImpl)
        }
        container.register(NotificationRepository.self) { resolver in
            let notificationApi = resolver.resolve(NotificationApi.self)!
            return NotificationRepositoryImpl(notificationApi)
        }
        container.register(GameInfoRepository.self) { resolver in
            let gameApi = resolver.resolve(GameApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return GameInfoRepositoryImpl(gameApi, httpClient)
        }
        container.register(CustomServiceRepository.self) { resolver in
            let csApi = resolver.resolve(CustomServiceApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            let local = resolver.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        container.register(IAuthRepository.self) { resolver in
            let api = resolver.resolve(AuthenticationApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return IAuthRepositoryImpl(api, httpClient)
        }
        container.register(SystemRepository.self) { resolver in
            let api = resolver.resolve(PortalApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return SystemRepositoryImpl(api, httpClient: httpClient)
        }
        container.register(ResetPasswordRepository.self) { resolver in
            let api = resolver.resolve(AuthenticationApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return IAuthRepositoryImpl(api, httpClient)
        }
        container.register(SystemSignalRepository.self) { resolver in
            let httpClient = resolver.resolve(HttpClient.self)!
            return SystemSignalRepositoryImpl(httpClient)
        }
        container.register(LocalStorageRepositoryImpl.self) { _ in
            return LocalStorageRepositoryImpl()
        }
        container.register(SettingStore.self) { _ in
            return SettingStore()
        }
        container.register(DepositRepository.self) { resolver in
            let bankApi = resolver.resolve(BankApi.self)!
            return DepositRepositoryImpl(bankApi)
        }
        container.register(ImageRepository.self) { resolver in
            let imageApi = resolver.resolve(ImageApi.self)!
            return ImageRepositoryImpl(imageApi)
        }
        container.register(BankRepository.self) { resolver in
            let bankApi = resolver.resolve(BankApi.self)!
            return BankRepositoryImpl(bankApi)
        }
        container.register(WithdrawalRepository.self) { resolver in
            let bankApi = resolver.resolve(BankApi.self)!
            let imageApi = resolver.resolve(ImageApi.self)!
            let cpsApi = resolver.resolve(CPSApi.self)!
            let repoBank = resolver.resolve(BankRepository.self)!
            let playerLocaleConfiguration = resolver.resolve(PlayerLocaleConfiguration.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return WithdrawalRepositoryImpl(bankApi, imageApi: imageApi, cpsApi: cpsApi, bankRepository: repoBank, playerLocaleConfiguration: playerLocaleConfiguration, httpClient: httpClient)
        }
        container.register(CasinoRecordRepository.self) { resolver in
            let casinoApi = resolver.resolve(CasinoApi.self)!
            let playerConfiguration = resolver.resolve(PlayerConfiguration.self)!
            return CasinoRecordRepositoryImpl(casinoApi, playerConfiguation: playerConfiguration)
        }
        container.register(CasinoRepository.self) { resolver in
            let casinoApi = resolver.resolve(CasinoApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return CasinoRepositoryImpl(casinoApi, httpClient: httpClient)
        }
        container.register(SlotRepository.self) { resolver in
            let slotApi = resolver.resolve(SlotApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return SlotRepositoryImpl(slotApi, httpClient: httpClient)
        }
        container.register(SlotRecordRepository.self) { resolver in
            let slotApi = resolver.resolve(SlotApi.self)!
            let playerConfiguration = resolver.resolve(PlayerConfiguration.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return SlotRecordRepositoryImpl(slotApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        container.register(NumberGameRepository.self) { resolver in
            let numberGameApi = resolver.resolve(NumberGameApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return NumberGameRepositoryImpl(numberGameApi, httpClient: httpClient)
        }
        container.register(NumberGameRecordRepository.self) { resolver in
            let numberGameApi = resolver.resolve(NumberGameApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return NumberGameRecordRepositoryImpl(numberGameApi, httpClient: httpClient)
        }
        container.register(P2PRepository.self) { resolver in
            let p2pApi = resolver.resolve(P2PApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return P2PRepositoryImpl(p2pApi, httpClient: httpClient)
        }
        container.register(P2PRecordRepository.self) { resolver in
            let p2pApi = resolver.resolve(P2PApi.self)!
            let playerConfiguration = resolver.resolve(PlayerConfiguration.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return P2PRecordRepositoryImpl(p2pApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        container.register(ArcadeRecordRepository.self) { resolver in
            let arcadeApi = resolver.resolve(ArcadeApi.self)!
            let playerConfiguration = resolver.resolve(PlayerConfiguration.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return ArcadeRecordRepositoryImpl(arcadeApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        container.register(ArcadeRepository.self) { resolver in
            let arcadeApi = resolver.resolve(ArcadeApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return ArcadeRepositoryImpl(arcadeApi, httpClient: httpClient)
        }
        container.register(PromotionRepository.self) { resolver in
            let promotionApi = resolver.resolve(PromotionApi.self)!
            return PromotionRepositoryImpl(promotionApi)
        }
        container.register(TransactionLogRepository.self) { resolver in
            let promotionApi = resolver.resolve(TransactionLogApi.self)!
            return TransactionLogRepositoryImpl(promotionApi)
        }
        container.register(SurveyInfraService.self) { resolver in
            let csApi = resolver.resolve(CustomServiceApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            let local = resolver.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        container.register(CustomerInfraService.self) { resolver in
            let csApi = resolver.resolve(CustomServiceApi.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            let local = resolver.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        container.register(AccountPatternGenerator.self) { resolver in
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return AccountPatternGeneratorFactory.create(repoLocalStorage.getSupportLocale())
        }
        container.register(LocalizationRepository.self) { resolver in
            let playerLocaleConfiguration = resolver.resolve(PlayerLocaleConfiguration.self)!
            let portalApi = resolver.resolve(PortalApi.self)!
            return LocalizationRepositoryImpl(playerLocaleConfiguration, portalApi)
        }
        container.register(AppUpdateRepository.self) { resolver in
            let portalApi = resolver.resolve(PortalApi.self)!
            return AppUpdateRepositoryImpl(portalApi)
        }
        container.register(PlayerLocaleConfiguration.self) { resolver in
            return resolver.resolve(LocalStorageRepositoryImpl.self)!
        }
        container.register(MemoryCacheImpl.self) { _ in
            return MemoryCacheImpl()
        }.inObjectScope(.lobby)
    }
    
    func registUsecase(){
        container.register(RegisterUseCase.self) { resolver in
            let auth = resolver.resolve(IAuthRepository.self)!
            let player = resolver.resolve(PlayerRepository.self)!
            return RegisterUseCaseImpl(auth, player)
        }
        container.register(ConfigurationUseCase.self) { resolver in
            let repo = resolver.resolve(PlayerRepository.self)!
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return ConfigurationUseCaseImpl.init(repo, repoLocalStorage)
        }
        container.register(AuthenticationUseCase.self) { resolver in
            let repoAuth = resolver.resolve(IAuthRepository.self)!
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            let settingStore = resolver.resolve(SettingStore.self)!
            return AuthenticationUseCaseImpl(repoAuth, repoPlayer, repoLocalStorage, settingStore)
        }
        container.register(GetSystemStatusUseCase.self) { resolver in
            let repoSystem = resolver.resolve(SystemRepository.self)!
            return GetSystemStatusUseCaseImpl(repoSystem)
        }
        container.register(ResetPasswordUseCase.self) { resolver in
            let repoSystem = resolver.resolve(ResetPasswordRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return ResetPasswordUseCaseImpl(repoSystem, localRepository: repoLocal)
        }
        container.register(SystemSignalRUseCase.self) { resolver in
            let repoSystem = resolver.resolve(SystemSignalRepository.self)!
            return SystemSignalRUseCaseImpl(repoSystem)
        }
        container.register(PlayerDataUseCase.self) { resolver in
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            let settingStore = resolver.resolve(SettingStore.self)!
            return PlayerDataUseCaseImpl(repoPlayer, localRepository: repoLocal, settingStore: settingStore)
        }
        container.register(DepositUseCase.self) { resolver in
            let repoDeposit = resolver.resolve(DepositRepository.self)!
            return DepositUseCaseImpl(repoDeposit)
        }
        container.register(NotificationUseCase.self) { resolver in
            let repo = resolver.resolve(NotificationRepository.self)!
            return NotificationUseCaseImpl(repo)
        }
        container.register(UploadImageUseCase.self) { resolver in
            let repoImage = resolver.resolve(ImageRepository.self)!
            return UploadImageUseCaseImpl(repoImage)
        }
        container.register(WithdrawalUseCase.self) { resolver in
            let repoWithdrawal = resolver.resolve(WithdrawalRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalUseCaseImpl(repoWithdrawal, repoLocal)
        }
        container.register(BankUseCase.self) { resolver in
            let repoBank = resolver.resolve(BankRepository.self)!
            return BankUseCaseImpl(repoBank)
        }
        container.register(CasinoRecordUseCase.self) { resolver in
            let repoCasinoRecord = resolver.resolve(CasinoRecordRepository.self)!
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            return CasinoRecordUseCaseImpl(repoCasinoRecord, playerRepository: repoPlayer)
        }
        container.register(CasinoUseCase.self) { resolver in
            let repo = resolver.resolve(CasinoRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return CasinoUseCaseImpl(repo, repoLocal)
        }
        container.register(SlotUseCase.self) { resolver in
            let repo = resolver.resolve(SlotRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return SlotUseCaseImpl(repo, repoLocal)
        }
        container.register(SlotRecordUseCase.self) { resolver in
            let repo = resolver.resolve(SlotRecordRepository.self)!
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            return SlotRecordUseCaseImpl(repo, playerRepository: repoPlayer)
        }
        container.register(NumberGameUseCase.self) { resolver in
            let repo = resolver.resolve(NumberGameRepository.self)!
            let repoLocal = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return NumberGameUseCasaImp(repo, repoLocal)
        }
        container.register(NumberGameRecordUseCase.self) { resolver in
            let repo = resolver.resolve(NumberGameRecordRepository.self)!
            return NumberGameRecordUseCaseImpl(numberGameRecordRepository: repo)
        }
        container.register(P2PUseCase.self) { resolver in
            let repo = resolver.resolve(P2PRepository.self)!
            return P2PUseCaseImpl(repo)
        }
        container.register(P2PRecordUseCase.self) { resolver in
            let repo = resolver.resolve(P2PRecordRepository.self)!
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            return P2PRecordUseCaseImpl(repo, repoPlayer)
        }
        container.register(ArcadeRecordUseCase.self) { resolver in
            let repo = resolver.resolve(ArcadeRecordRepository.self)!
            let repoPlayer = resolver.resolve(PlayerRepository.self)!
            return ArcadeRecordUseCaseImpl(repo, repoPlayer)
        }
        container.register(ArcadeUseCase.self) { resolver in
            let repo = resolver.resolve(ArcadeRepository.self)!
            return ArcadeUseCaseImpl(repo)
        }
        container.register(PromotionUseCase.self) { resolver in
            let repo = resolver.resolve(PromotionRepository.self)!
            let player = resolver.resolve(PlayerRepository.self)!
            return PromotionUseCaseImpl(repo, playerRepository: player)
        }
        container.register(TransactionLogUseCase.self) { resolver in
            let repo = resolver.resolve(TransactionLogRepository.self)!
            let player = resolver.resolve(PlayerRepository.self)!
            return TransactionLogUseCaseImpl(repo, player)
        }
        container.register(CustomerServiceUseCase.self) { resolver in
            let repo = resolver.resolve(CustomServiceRepository.self)!
            let infra = resolver.resolve(CustomerInfraService.self)!
            let surver = resolver.resolve(SurveyInfraService.self)!
            return CustomerServiceUseCaseImpl(repo, customerInfraService: infra, surveyInfraService: surver)
        }
        container.register(CustomerServiceSurveyUseCase.self) { resolver in
            let repo = resolver.resolve(CustomServiceRepository.self)!
            let surver = resolver.resolve(SurveyInfraService.self)!
            return CustomerServiceSurveyUseCaseImpl(repo, surveyInfraService: surver)
        }
        container.register(ChatRoomHistoryUseCase.self) { resolver in
            let repo = resolver.resolve(CustomServiceRepository.self)!
            let infra = resolver.resolve(CustomerInfraService.self)!
            let surver = resolver.resolve(SurveyInfraService.self)!
            return CustomerServiceUseCaseImpl(repo, customerInfraService: infra, surveyInfraService: surver)
        }
        container.register(LocalizationPolicyUseCase.self) { resolver in
            let repoLocalization = resolver.resolve(LocalizationRepository.self)!
            return LocalizationPolicyUseCaseImpl(repoLocalization)
        }
        container.register(AppVersionUpdateUseCase.self) { resolver in
            let repo = resolver.resolve(AppUpdateRepository.self)!
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return AppVersionUpdateUseCaseImpl(repo, repoLocalStorage)
        }
    }
    
    func registNavigator() {
        container.register(DepositNavigator.self) { _ in
            return DepositNavigatorImpl()
        }
    }
    
    func registViewModel(){
        container.register(CryptoDepositViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let navigator = resolver.resolve(DepositNavigator.self)!
            return CryptoDepositViewModel(depositService: deposit, navigator: navigator)
        }
        container.register(ThirdPartyDepositViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let navigator = resolver.resolve(DepositNavigator.self)!
            let httpClient = resolver.resolve(HttpClient.self)!
            return ThirdPartyDepositViewModel(playerUseCase: playerUseCase, depositService: deposit, navigator: navigator, httpClient: httpClient)
        }
        container.register(OfflineViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let pattern = resolver.resolve(AccountPatternGenerator.self)!
            let bankUseCase = resolver.resolve(BankUseCase.self)!
            let navigator = resolver.resolve(DepositNavigator.self)!
            let localStorageRepo = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return OfflineViewModel(deposit, playerUseCase: playerUseCase, accountPatternGenerator: pattern, bankUseCase: bankUseCase, navigator: navigator, localStorageRepo: localStorageRepo)
        }.inObjectScope(.depositFlow)
        container.register(DepositViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let depositUseCase = resolver.resolve(DepositUseCase.self)!
            return DepositViewModel(deposit, depositUseCase: depositUseCase)
        }
        container.register(DepositLogViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            return DepositLogViewModel(deposit)
        }
        container.register(NotificationViewModel.self) { resolver in
            let useCase = resolver.resolve(NotificationUseCase.self)!
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            let systemUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            return NotificationViewModel(useCase: useCase, configurationUseCase: usecaseConfiguration, systemStatusUseCase: systemUseCase)
        }
        container.register(NavigationViewModel.self) { (resolver)  in
            let usecaseAuth = resolver.resolve(AuthenticationUseCase.self)!
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let localizationUseCase = resolver.resolve(LocalizationPolicyUseCase.self)!
            let getSystemStatusUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            return NavigationViewModel(usecaseAuth, playerUseCase, localizationUseCase, getSystemStatusUseCase)
        }
        container.register(LoginViewModel.self) { resolver in
            let usecaseAuthentication = resolver.resolve(AuthenticationUseCase.self)!
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            return LoginViewModel(usecaseAuthentication, usecaseConfiguration)
        }
        container.register(SignupUserInfoViewModel.self){ resolver in
            let registerUseCase = resolver.resolve(RegisterUseCase.self)!
            let systemUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            let pattern = resolver.resolve(AccountPatternGenerator.self)!
            return SignupUserInfoViewModel(registerUseCase, systemUseCase, pattern)
        }
        container.register(SignupPhoneViewModel.self) { resolver in
            let usecase = resolver.resolve(RegisterUseCase.self)!
            return SignupPhoneViewModel(usecase)
        }
        container.register(SignupEmailViewModel.self) { resolver in
            let usecaseRegister = resolver.resolve(RegisterUseCase.self)!
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            let usecaseAuthentication = resolver.resolve(AuthenticationUseCase.self)!
            return SignupEmailViewModel(usecaseRegister, usecaseConfiguration, usecaseAuthentication)
        }
        container.register(DefaultProductViewModel.self) { resolver in
            let usecase = resolver.resolve(ConfigurationUseCase.self)!
            return DefaultProductViewModel(usecase)
        }
        container.register(ResetPasswordViewModel.self) { resolver in
            let usecaseAuthentication = resolver.resolve(ResetPasswordUseCase.self)!
            let systemUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            let localStorageRepo = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return ResetPasswordViewModel(usecaseAuthentication, systemUseCase, localStorageRepo)
        }
        container.register(SystemViewModel.self) { resolver in
            let systemSignalRUseCase = resolver.resolve(SystemSignalRUseCase.self)!
            return SystemViewModel(systemUseCase: systemSignalRUseCase)
        }
        container.register(ServiceStatusViewModel.self) { resolver in
            let systemUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            let localStorageRepo = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return ServiceStatusViewModel(systemStatusUseCase: systemUseCase, localStorageRepo: localStorageRepo)
        }
        container.register(PlayerViewModel.self) { resolver in
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let authUseCase = resolver.resolve(AuthenticationUseCase.self)!
            return PlayerViewModel(playerUseCase: playerUseCase, authUsecase: authUseCase)
        }
        container.register(UploadPhotoViewModel.self) { resolver in
            let imageUseCase = resolver.resolve(UploadImageUseCase.self)!
            return UploadPhotoViewModel(imageUseCase: imageUseCase)
        }
        container.register(WithdrawalViewModel.self) { resolver in
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalViewModel(withdrawalUseCase: withdrawalUseCase, localStorageRepository: repoLocalStorage)
        }
        container.register(ManageCryptoBankCardViewModel.self) { resolver in
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            return ManageCryptoBankCardViewModel(withdrawalUseCase: withdrawalUseCase)
        }
        container.register(CryptoViewModel.self) { resolver in
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            let depositUseCase = resolver.resolve(DepositUseCase.self)!
            return CryptoViewModel(withdrawalUseCase: withdrawalUseCase, depositUseCase: depositUseCase)
        }
        container.register(AddBankViewModel.self) { resolver in
            return AddBankViewModel(resolver.resolve(LocalStorageRepositoryImpl.self)!,
                                    resolver.resolve(AuthenticationUseCase.self)!,
                                    resolver.resolve(BankUseCase.self)!,
                                    resolver.resolve(WithdrawalUseCase.self)!,
                                    resolver.resolve(PlayerDataUseCase.self)!,
                                    resolver.resolve(AccountPatternGenerator.self)!)
        }
        container.register(WithdrawlLandingViewModel.self) { resolver in
            return WithdrawlLandingViewModel(resolver.resolve(WithdrawalUseCase.self)!)
        }
        container.register(WithdrawalRequestViewModel.self) { resolver in
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            return WithdrawalRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerDataUseCase: playerUseCase)
        }
        container.register(WithdrawalCryptoRequestViewModel.self) { resolver in
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let repoLocalStorage = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalCryptoRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerUseCase: playerUseCase, localStorageRepository: repoLocalStorage)
        }
        container.register(CasinoViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let casinoAppService = applicationFactory.casino()
            return CasinoViewModel(casinoRecordUseCase: resolver.resolve(CasinoRecordUseCase.self)!, casinoUseCase: resolver.resolve(CasinoUseCase.self)!, memoryCache: resolver.resolve(MemoryCacheImpl.self)!, casinoAppService: casinoAppService)
        }
        container.register(SlotViewModel.self) { resolver in
            return SlotViewModel(slotUseCase: resolver.resolve(SlotUseCase.self)!)
        }
        container.register(SlotBetViewModel.self) { resolver in
            return SlotBetViewModel(slotUseCase: resolver.resolve(SlotUseCase.self)!, slotRecordUseCase: resolver.resolve(SlotRecordUseCase.self)!)
        }
        container.register(NumberGameViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let numberGameService = applicationFactory.numberGame()
            return NumberGameViewModel(numberGameUseCase: resolver.resolve(NumberGameUseCase.self)!, memoryCache: resolver.resolve(MemoryCacheImpl.self)!, numberGameService: numberGameService)
        }
        container.register(NumberGameRecordViewModel.self) { resolver in
            return NumberGameRecordViewModel(numberGameRecordUseCase: resolver.resolve(NumberGameRecordUseCase.self)!)
        }
        container.register(CryptoVerifyViewModel.self) { resolver in
            return CryptoVerifyViewModel(playerUseCase: resolver.resolve(PlayerDataUseCase.self)!, withdrawalUseCase:  resolver.resolve(WithdrawalUseCase.self)!, systemUseCase: resolver.resolve(GetSystemStatusUseCase.self)!)
        }
        container.register(P2PViewModel.self) { resolver in
            return P2PViewModel(p2pUseCase: resolver.resolve(P2PUseCase.self)!)
        }
        container.register(P2PBetViewModel.self) { resolver in
            return P2PBetViewModel(p2pRecordUseCase: resolver.resolve(P2PRecordUseCase.self)!)
        }
        container.register(ArcadeRecordViewModel.self) { resolver in
            return ArcadeRecordViewModel(arcadeRecordUseCase: resolver.resolve(ArcadeRecordUseCase.self)!)
        }
        container.register(ArcadeViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let arcadeAppService = applicationFactory.arcade()
            return ArcadeViewModel(arcadeUseCase: resolver.resolve(ArcadeUseCase.self)!, memoryCache: resolver.resolve(MemoryCacheImpl.self)!, arcadeAppService: arcadeAppService)
        }
        container.register(PromotionViewModel.self) { resolver in
            return PromotionViewModel(promotionUseCase: resolver.resolve(PromotionUseCase.self)!, playerUseCase: resolver.resolve(PlayerDataUseCase.self)!)
        }
        container.register(PromotionHistoryViewModel.self) { resolver in
            return PromotionHistoryViewModel(promotionUseCase: resolver.resolve(PromotionUseCase.self)!)
        }
        container.register(TransactionLogViewModel.self) { resolver in
            return TransactionLogViewModel(transactionLogUseCase: resolver.resolve(TransactionLogUseCase.self)!)
        }
        container.register(CustomerServiceViewModel.self) { resolver in
            return CustomerServiceViewModel(customerServiceUseCase: resolver.resolve(CustomerServiceUseCase.self)!)
        }
        container.register(SurveyViewModel.self) { resolver in
            return SurveyViewModel(resolver.resolve(CustomerServiceSurveyUseCase.self)!, resolver.resolve(AuthenticationUseCase.self)!)
        }
        container.register(CustomerServiceHistoryViewModel.self) { resolver in
            return CustomerServiceHistoryViewModel(historyUseCase: resolver.resolve(ChatRoomHistoryUseCase.self)!)
        }
        container.register(TermsViewModel.self) { resolver in
            let systemUseCase = resolver.resolve(GetSystemStatusUseCase.self)!
            return TermsViewModel(localizationPolicyUseCase: resolver.resolve(LocalizationPolicyUseCase.self)!, systemStatusUseCase: systemUseCase)
        }
        container.register(ModifyProfileViewModel.self) { resolver in
            let playerUseCase = resolver.resolve(PlayerDataUseCase.self)!
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            let withdrawalUseCase = resolver.resolve(WithdrawalUseCase.self)!
            let pattern = resolver.resolve(AccountPatternGenerator.self)!
            return ModifyProfileViewModel(playerUseCase, usecaseConfiguration, withdrawalUseCase, pattern)
        }
        container.register(CommonOtpViewModel.self) { resolver in
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            return CommonOtpViewModel(usecaseConfiguration)
        }
        container.register(ConfigurationViewModel.self) { resolver in
            let usecaseConfiguration = resolver.resolve(ConfigurationUseCase.self)!
            return ConfigurationViewModel(usecaseConfiguration)
        }
        container.register(AppSynchronizeViewModel.self) { resolver in
            let appUpdateUseCase = resolver.resolve(AppVersionUpdateUseCase.self)!
            return AppSynchronizeViewModel(appUpdateUseCase: appUpdateUseCase)
        }.inObjectScope(.application)
        container.register(StarMergerViewModel.self) { resolver in
            let applicationFactory = resolver.resolve(ApplicationFactory.self)!
            let depositService = applicationFactory.deposit()
            return StarMergerViewModel(depositService: depositService)
        }
        container.register(NewLoginViewModel.self) { (resolver) in
            let authenticationUseCase = resolver.resolve(AuthenticationUseCase.self)!
            let configurationUseCase = resolver.resolve(ConfigurationUseCase.self)!
            let navigationViewModel = resolver.resolve(NavigationViewModel.self)!
            let localStorageRepo = resolver.resolve(LocalStorageRepositoryImpl.self)!
            return NewLoginViewModel(authenticationUseCase, configurationUseCase, navigationViewModel, localStorageRepo)
        }
    }
    
    func registSingleton() {
        container.register(LocalizeUtils.self) { resolver in
            return LocalizeUtils(playerLocaleConfiguration: resolver.resolve(PlayerLocaleConfiguration.self)!)
        }.inObjectScope(.application)
    }
}

extension ObjectScope {
    static let application = ObjectScope(storageFactory: PermanentStorage.init)
    static let lobby = ObjectScope(storageFactory: PermanentStorage.init)
    static let landing = ObjectScope(storageFactory: PermanentStorage.init)
    static let depositFlow = ObjectScope(storageFactory: PermanentStorage.init)
}
