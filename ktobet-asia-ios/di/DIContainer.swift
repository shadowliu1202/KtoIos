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
    }
    
    func registerPlayerConfig() {
        let ctner = container
        ctner.register(PlayerLocaleConfiguration.self) { resolver in
            return LocalStorageRepositoryImpl()
        }.inObjectScope(.lobby)
    }
    func registerHttpClient() {
        let ctner = container
        ctner.register(KtoURL.self) { (resolver) in
            return KtoURL(playConfig: resolver.resolve(PlayerLocaleConfiguration.self)!)
        }.inObjectScope(.lobby)
        ctner.register(HttpClient.self) { (resolver)  in
            return HttpClient(ktoUrl: resolver.resolve(KtoURL.self)!)
        }.inObjectScope(.lobby)
    }
    func registerCustomServicePresenter() {
        let ctner = container
        ctner.register(CustomServicePresenter.self) { (resolver)  in
            let csViewModel = DI.resolve(CustomerServiceViewModel.self)!
            let surveyViewModel = DI.resolve(SurveyViewModel.self)!
            return CustomServicePresenter(csViewModel: csViewModel, surveyViewModel: surveyViewModel)
        }.inObjectScope(.lobby)
    }
    func registFactory() {
        let ctner = container
        
        ctner.register(PlayerConfiguration.self) { (resolver)  in
            return LocalStorageRepositoryImpl()
        }.inObjectScope(.lobby)
        
        ctner.register(ExternalProtocolService.self) { (resolver)  in
            let httpClient = ctner.resolve(HttpClient.self)!
            return NetworkFactory(httpClient)
        }.inObjectScope(.lobby)
        
        ctner.register(ExternalStringService.self) { (resolver)  in
            return DepositStringServiceFactory()
        }.inObjectScope(.application)
        
        ctner.register(StringSupporter.self) { (resolver)  in
            return LocalizeUtils()
        }.inObjectScope(.application)
        
        
        ctner.register(ApplicationFactory.self) { (resolver)  in
            let local = ctner.resolve(PlayerConfiguration.self)!
            let network = ctner.resolve(ExternalProtocolService.self)!
            let stringService = ctner.resolve(ExternalStringService.self)!
            let localize = ctner.resolve(StringSupporter.self)!
            return ApplicationFactory(playerConfiguration: local,
                                      externalProtocolService: network,
                                      stringServiceFactory: stringService,
                                      stringSupporter: localize)
        }.inObjectScope(.lobby)
    }
    
    func registApi() {
        
        let ctner = container

        ctner.register(NotificationApi.self) { (resolver)  in
            let httpClient = ctner.resolve(HttpClient.self)!
            return NotificationApi(httpClient)
        }
        ctner.register(AuthenticationApi.self) { (resolver)  in
            let httpClient = ctner.resolve(HttpClient.self)!
            return AuthenticationApi(httpClient)
        }
        ctner.register(PlayerApi.self) { (resolver)  in
            let httpClient = ctner.resolve(HttpClient.self)!
            return PlayerApi(httpClient)
        }
        ctner.register(PortalApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return PortalApi(httpClient)
        }
        ctner.register(GameApi.self) { (resolver)  in
            let httpClient = ctner.resolve(HttpClient.self)!
            return GameApi(httpClient)
        }
        ctner.register(CustomServiceApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return CustomServiceApi(httpClient)
        }
        ctner.register(BankApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return BankApi(httpClient)
        }
        ctner.register(ImageApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return ImageApi(httpClient)
        }
        ctner.register(CasinoApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return CasinoApi(httpClient)
        }
        ctner.register(SlotApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return SlotApi(httpClient)
        }
        ctner.register(NumberGameApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return NumberGameApi(httpClient)
        }
        ctner.register(CPSApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return CPSApi(httpClient)
        }
        ctner.register(P2PApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return P2PApi(httpClient)
        }
        ctner.register(ArcadeApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return ArcadeApi(httpClient)
        }
        ctner.register(PromotionApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return PromotionApi(httpClient)
        }
        ctner.register(TransactionLogApi.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            return TransactionLogApi(httpClient)
        }
    }
    
    func registRepo(){
        let ctner = container
        
        ctner.register(PlayerRepository.self) { (resolver) in
            let httpClient = ctner.resolve(HttpClient.self)!
            let player = ctner.resolve(PlayerApi.self)!
            let portal = ctner.resolve(PortalApi.self)!
            let settingStore = ctner.resolve(SettingStore.self)!
            return PlayerRepositoryImpl(httpClient, player, portal, settingStore)
        }
        ctner.register(NotificationRepository.self) { (resolver) in
            let notificationApi = ctner.resolve(NotificationApi.self)!
            return NotificationRepositoryImpl(notificationApi)
        }
        ctner.register(GameInfoRepository.self) { (resolver) in
            let gameApi = ctner.resolve(GameApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return GameInfoRepositoryImpl(gameApi, httpClient)
        }
        ctner.register(CustomServiceRepository.self) { (resolver) in
            let csApi = ctner.resolve(CustomServiceApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            let local = ctner.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        ctner.register(IAuthRepository.self) { resolver in
            let api = ctner.resolve(AuthenticationApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return IAuthRepositoryImpl(api, httpClient)
        }
        ctner.register(SystemRepository.self) { resolver in
            let api = ctner.resolve(PortalApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return SystemRepositoryImpl(api, httpClient: httpClient)
        }
        ctner.register(ResetPasswordRepository.self) { resolver in
            let api = ctner.resolve(AuthenticationApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return IAuthRepositoryImpl(api, httpClient)
        }
        ctner.register(SystemSignalRepository.self) { resolver in
            let httpClient = ctner.resolve(HttpClient.self)!
            return SystemSignalRepositoryImpl(httpClient)
        }
        ctner.register(LocalStorageRepositoryImpl.self) { resolver in
            return LocalStorageRepositoryImpl()
        }
        ctner.register(SettingStore.self) { resolver in
            return SettingStore()
        }
        ctner.register(DepositRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            return DepositRepositoryImpl(bankApi)
        }
        ctner.register(ImageRepository.self) { resolver in
            let imageApi = ctner.resolve(ImageApi.self)!
            return ImageRepositoryImpl(imageApi)
        }
        ctner.register(BankRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            return BankRepositoryImpl(bankApi)
        }
        ctner.register(WithdrawalRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            let imageApi = ctner.resolve(ImageApi.self)!
            let cpsApi = ctner.resolve(CPSApi.self)!
            let repoBank = ctner.resolve(BankRepository.self)!
            let localStorageRepo = ctner.resolve(LocalStorageRepositoryImpl.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return WithdrawalRepositoryImpl(bankApi, imageApi: imageApi, cpsApi: cpsApi, bankRepository: repoBank, localStorageRepo: localStorageRepo, httpClient: httpClient)
        }
        ctner.register(CasinoRecordRepository.self) { resolver in
            let casinoApi = ctner.resolve(CasinoApi.self)!
            let playerConfiguration = ctner.resolve(PlayerConfiguration.self)!
            return CasinoRecordRepositoryImpl(casinoApi, playerConfiguation: playerConfiguration)
        }
        ctner.register(CasinoRepository.self) { resolver in
            let casinoApi = ctner.resolve(CasinoApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return CasinoRepositoryImpl(casinoApi, httpClient: httpClient)
        }
        ctner.register(SlotRepository.self) { resolver in
            let slotApi = ctner.resolve(SlotApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return SlotRepositoryImpl(slotApi, httpClient: httpClient)
        }
        ctner.register(SlotRecordRepository.self) { resolver in
            let slotApi = ctner.resolve(SlotApi.self)!
            let playerConfiguration = ctner.resolve(PlayerConfiguration.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return SlotRecordRepositoryImpl(slotApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        ctner.register(NumberGameRepository.self) { (resolver) in
            let numberGameApi = ctner.resolve(NumberGameApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return NumberGameRepositoryImpl(numberGameApi, httpClient: httpClient)
        }
        ctner.register(NumberGameRecordRepository.self) { (resolver) in
            let numberGameApi = ctner.resolve(NumberGameApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return NumberGameRecordRepositoryImpl(numberGameApi, httpClient: httpClient)
        }
        ctner.register(P2PRepository.self) { (resolver) in
            let p2pApi = ctner.resolve(P2PApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return P2PRepositoryImpl(p2pApi, httpClient: httpClient)
        }
        ctner.register(P2PRecordRepository.self) { (resolver) in
            let p2pApi = ctner.resolve(P2PApi.self)!
            let playerConfiguration = ctner.resolve(PlayerConfiguration.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return P2PRecordRepositoryImpl(p2pApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        ctner.register(ArcadeRecordRepository.self) { (resolver) in
            let arcadeApi = ctner.resolve(ArcadeApi.self)!
            let playerConfiguration = ctner.resolve(PlayerConfiguration.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return ArcadeRecordRepositoryImpl(arcadeApi, playerConfiguation: playerConfiguration, httpClient: httpClient)
        }
        ctner.register(ArcadeRepository.self) { (resolver) in
            let arcadeApi = ctner.resolve(ArcadeApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return ArcadeRepositoryImpl(arcadeApi, httpClient: httpClient)
        }
        ctner.register(PromotionRepository.self) { (resolver) in
            let promotionApi = ctner.resolve(PromotionApi.self)!
            return PromotionRepositoryImpl(promotionApi)
        }
        ctner.register(TransactionLogRepository.self) { (resolver) in
            let promotionApi = ctner.resolve(TransactionLogApi.self)!
            return TransactionLogRepositoryImpl(promotionApi)
        }
        ctner.register(SurveyInfraService.self) { (resolver) in
            let csApi = ctner.resolve(CustomServiceApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            let local = ctner.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        ctner.register(CustomerInfraService.self) { (resolver) in
            let csApi = ctner.resolve(CustomServiceApi.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            let local = ctner.resolve(PlayerConfiguration.self)!
            return CustomServiceRepositoryImpl(csApi, httpClient, local)
        }
        ctner.register(AccountPatternGenerator.self) { resolver in
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return AccountPatternGeneratorFactory.create(repoLocalStorage.getSupportLocale())
        }
        ctner.register(LocalizationRepository.self) { (resolver) in
            let portalApi = ctner.resolve(PortalApi.self)!
            return LocalizationRepositoryImpl(portalApi)
        }
        ctner.register(AppUpdateRepository.self) { resolver in
            let portalApi = ctner.resolve(PortalApi.self)!
            return AppUpdateRepositoryImpl(portalApi)
        }
        ctner.register(PlayerLocaleConfiguration.self) { resolver in
            return ctner.resolve(LocalStorageRepositoryImpl.self)!
        }
    }
    
    func registUsecase(){
        let ctner = container
        
        ctner.register(RegisterUseCase.self) { (resolver)  in
            let auth = ctner.resolve(IAuthRepository.self)!
            let player = ctner.resolve(PlayerRepository.self)!
            return RegisterUseCaseImpl(auth, player)
        }
        ctner.register(ConfigurationUseCase.self) { (resolver) in
            let repo = ctner.resolve(PlayerRepository.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return ConfigurationUseCaseImpl.init(repo, repoLocalStorage)
        }
        ctner.register(AuthenticationUseCase.self) { (resolver)  in
            let repoAuth = ctner.resolve(IAuthRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            let settingStore = ctner.resolve(SettingStore.self)!
            return AuthenticationUseCaseImpl(repoAuth, repoPlayer, repoLocalStorage, settingStore)
        }
        ctner.register(GetSystemStatusUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemRepository.self)!
            return GetSystemStatusUseCaseImpl(repoSystem)
        }
        ctner.register(ResetPasswordUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(ResetPasswordRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return ResetPasswordUseCaseImpl(repoSystem, localRepository: repoLocal)
        }
        ctner.register(SystemSignalRUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemSignalRepository.self)!
            return SystemSignalRUseCaseImpl(repoSystem)
        }
        ctner.register(PlayerDataUseCase.self) { (resolver)  in
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            let settingStore = ctner.resolve(SettingStore.self)!
            return PlayerDataUseCaseImpl(repoPlayer, localRepository: repoLocal, settingStore: settingStore)
        }
        ctner.register(DepositUseCase.self) { (resolver)  in
            let repoDeposit = ctner.resolve(DepositRepository.self)!
            return DepositUseCaseImpl(repoDeposit)
        }
        ctner.register(NotificationUseCase.self) { (resolver)  in
            let repo = ctner.resolve(NotificationRepository.self)!
            return NotificationUseCaseImpl(repo)
        }
        ctner.register(UploadImageUseCase.self) { (resolver)  in
            let repoImage = ctner.resolve(ImageRepository.self)!
            return UploadImageUseCaseImpl(repoImage)
        }
        ctner.register(WithdrawalUseCase.self) { (resolver)  in
            let repoWithdrawal = ctner.resolve(WithdrawalRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalUseCaseImpl(repoWithdrawal, repoLocal)
        }
        ctner.register(BankUseCase.self) { (resolver)  in
            let repoBank = ctner.resolve(BankRepository.self)!
            return BankUseCaseImpl(repoBank)
        }
        ctner.register(CasinoRecordUseCase.self) { (resolver)  in
            let repoCasinoRecord = ctner.resolve(CasinoRecordRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            return CasinoRecordUseCaseImpl(repoCasinoRecord, playerRepository: repoPlayer)
        }
        ctner.register(CasinoUseCase.self) { (resolver) in
            let repo = ctner.resolve(CasinoRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return CasinoUseCaseImpl(repo, repoLocal)
        }
        ctner.register(SlotUseCase.self) { (resolver) in
            let repo = ctner.resolve(SlotRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return SlotUseCaseImpl(repo, repoLocal)
        }
        ctner.register(SlotRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(SlotRecordRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            return SlotRecordUseCaseImpl(repo, playerRepository: repoPlayer)
        }
        ctner.register(NumberGameUseCase.self) { (resolver) in
            let repo = ctner.resolve(NumberGameRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return NumberGameUseCasaImp(repo, repoLocal)
        }
        ctner.register(NumberGameRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(NumberGameRecordRepository.self)!
            return NumberGameRecordUseCaseImpl(numberGameRecordRepository: repo)
        }
        ctner.register(P2PUseCase.self) { (resolver) in
            let repo = ctner.resolve(P2PRepository.self)!
            return P2PUseCaseImpl(repo)
        }
        ctner.register(P2PRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(P2PRecordRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            return P2PRecordUseCaseImpl(repo, repoPlayer)
        }
        ctner.register(ArcadeRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(ArcadeRecordRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            return ArcadeRecordUseCaseImpl(repo, repoPlayer)
        }
        ctner.register(ArcadeUseCase.self) { (resolver) in
            let repo = ctner.resolve(ArcadeRepository.self)!
            return ArcadeUseCaseImpl(repo)
        }
        ctner.register(PromotionUseCase.self) { (resolver) in
            let repo = ctner.resolve(PromotionRepository.self)!
            let player = ctner.resolve(PlayerRepository.self)!
            return PromotionUseCaseImpl(repo, playerRepository: player)
        }
        ctner.register(TransactionLogUseCase.self) { (resolver) in
            let repo = ctner.resolve(TransactionLogRepository.self)!
            let player = ctner.resolve(PlayerRepository.self)!
            return TransactionLogUseCaseImpl(repo, player)
        }
        ctner.register(CustomerServiceUseCase.self) { (resolver) in
            let repo = ctner.resolve(CustomServiceRepository.self)!
            let infra = ctner.resolve(CustomerInfraService.self)!
            let surver = ctner.resolve(SurveyInfraService.self)!
            return CustomerServiceUseCaseImpl(repo, customerInfraService: infra, surveyInfraService: surver)
        }
        ctner.register(CustomerServiceSurveyUseCase.self) { (resolver) in
            let repo = ctner.resolve(CustomServiceRepository.self)!
            let surver = ctner.resolve(SurveyInfraService.self)!
            return CustomerServiceSurveyUseCaseImpl(repo, surveyInfraService: surver)
        }
        ctner.register(ChatRoomHistoryUseCase.self) { (resolver) in
            let repo = ctner.resolve(CustomServiceRepository.self)!
            let infra = ctner.resolve(CustomerInfraService.self)!
            let surver = ctner.resolve(SurveyInfraService.self)!
            return CustomerServiceUseCaseImpl(repo, customerInfraService: infra, surveyInfraService: surver)
        }
        ctner.register(LocalizationPolicyUseCase.self) { (resolver)  in
            let repoLocalization = ctner.resolve(LocalizationRepository.self)!
            return LocalizationPolicyUseCaseImpl(repoLocalization)
        }
        ctner.register(AppVersionUpdateUseCase.self) { (resolver) in
            let repo = ctner.resolve(AppUpdateRepository.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return AppVersionUpdateUseCaseImpl(repo, repoLocalStorage)
        }
    }
    
    func registNavigator() {
        let ctner = container
        
        ctner.register(DepositNavigator.self) { (resolver) in
            return DepositNavigatorImpl()
        }
    }
    
    func registViewModel(){
        let ctner = container
        
        ctner.register(CryptoDepositViewModel.self) { resolver in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let navigator = ctner.resolve(DepositNavigator.self)!
            return CryptoDepositViewModel(depositService: deposit, navigator: navigator)
        }
        ctner.register(ThirdPartyDepositViewModel.self) { resolver in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let navigator = ctner.resolve(DepositNavigator.self)!
            let httpClient = ctner.resolve(HttpClient.self)!
            return ThirdPartyDepositViewModel(playerUseCase: playerUseCase, depositService: deposit, navigator: navigator, httpClient: httpClient)
        }
        ctner.register(OfflineViewModel.self) { resolver in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let pattern = ctner.resolve(AccountPatternGenerator.self)!
            let bankUseCase = ctner.resolve(BankUseCase.self)!
            let navigator = ctner.resolve(DepositNavigator.self)!
            let localStorageRepo = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return OfflineViewModel(deposit, playerUseCase: playerUseCase, accountPatternGenerator: pattern, bankUseCase: bankUseCase, navigator: navigator, localStorageRepo: localStorageRepo)
        }.inObjectScope(.depositFlow)
        ctner.register(DepositViewModel.self) { resolver in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            let depositUseCase = ctner.resolve(DepositUseCase.self)!
            return DepositViewModel(deposit, depositUseCase: depositUseCase)
        }
        ctner.register(DepositLogViewModel.self) { resolver in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let deposit = applicationFactory.deposit()
            return DepositLogViewModel(deposit)
        }
        ctner.register(NotificationViewModel.self) { resolver in
            let useCase = ctner.resolve(NotificationUseCase.self)!
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            return NotificationViewModel(useCase: useCase, configurationUseCase: usecaseConfiguration, systemStatusUseCase: systemUseCase)
        }
        ctner.register(LaunchViewModel.self) { (resolver)  in
            let usecaseAuth = ctner.resolve(AuthenticationUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let localizationUseCase = ctner.resolve(LocalizationPolicyUseCase.self)!
            return LaunchViewModel(usecaseAuth, playerUseCase: playerUseCase, localizationPolicyUseCase: localizationUseCase)
        }
        ctner.register(LoginViewModel.self) { resolver  in
            let usecaseAuthentication = ctner.resolve(AuthenticationUseCase.self)!
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            return LoginViewModel(usecaseAuthentication, usecaseConfiguration)
        }
        ctner.register(SignupUserInfoViewModel.self){ resolver in
            let registerUseCase = ctner.resolve(RegisterUseCase.self)!
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            let pattern = ctner.resolve(AccountPatternGenerator.self)!
            return SignupUserInfoViewModel(registerUseCase, systemUseCase, pattern)
        }
        ctner.register(SignupPhoneViewModel.self) { resolver in
            let usecase = ctner.resolve(RegisterUseCase.self)!
            return SignupPhoneViewModel(usecase)
        }
        ctner.register(SignupEmailViewModel.self) { resolver in
            let usecaseRegister = ctner.resolve(RegisterUseCase.self)!
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            let usecaseAuthentication = ctner.resolve(AuthenticationUseCase.self)!
            return SignupEmailViewModel(usecaseRegister, usecaseConfiguration, usecaseAuthentication)
        }
        ctner.register(DefaultProductViewModel.self) { resolver in
            let usecase = ctner.resolve(ConfigurationUseCase.self)!
            return DefaultProductViewModel(usecase)
        }
        ctner.register(ResetPasswordViewModel.self) { resolver  in
            let usecaseAuthentication = ctner.resolve(ResetPasswordUseCase.self)!
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            let localStorageRepo = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return ResetPasswordViewModel(usecaseAuthentication, systemUseCase, localStorageRepo)
        }
        ctner.register(SystemViewModel.self) { (resolver) in
            let systemSignalRUseCase = ctner.resolve(SystemSignalRUseCase.self)!
            return SystemViewModel(systemUseCase: systemSignalRUseCase)
        }
        ctner.register(ServiceStatusViewModel.self) { resolver  in
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            let localStorageRepo = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return ServiceStatusViewModel(usecaseSystemStatus: systemUseCase, localStorageRepo: localStorageRepo)
        }
        ctner.register(PlayerViewModel.self) { (resolver) in
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let authUseCase = ctner.resolve(AuthenticationUseCase.self)!
            return PlayerViewModel(playerUseCase: playerUseCase, authUsecase: authUseCase)
        }
        ctner.register(UploadPhotoViewModel.self) { (resolver) in
            let imageUseCase = ctner.resolve(UploadImageUseCase.self)!
            return UploadPhotoViewModel(imageUseCase: imageUseCase)
        }
        ctner.register(WithdrawalViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalViewModel(withdrawalUseCase: withdrawalUseCase, localStorageRepository: repoLocalStorage)
        }
        ctner.register(ManageCryptoBankCardViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            return ManageCryptoBankCardViewModel(withdrawalUseCase: withdrawalUseCase)
        }
        ctner.register(CryptoViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let depositUseCase = ctner.resolve(DepositUseCase.self)!
            return CryptoViewModel(withdrawalUseCase: withdrawalUseCase, depositUseCase: depositUseCase)
        }
        ctner.register(AddBankViewModel.self) { (resolver) in
            return AddBankViewModel(ctner.resolve(LocalStorageRepositoryImpl.self)!,
                                    ctner.resolve(AuthenticationUseCase.self)!,
                                    ctner.resolve(BankUseCase.self)!,
                                    ctner.resolve(WithdrawalUseCase.self)!,
                                    ctner.resolve(PlayerDataUseCase.self)!,
                                    ctner.resolve(AccountPatternGenerator.self)!)
        }
        ctner.register(WithdrawlLandingViewModel.self) { (resolver) in
            return WithdrawlLandingViewModel(ctner.resolve(WithdrawalUseCase.self)!)
        }
        ctner.register(WithdrawalRequestViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            return WithdrawalRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerDataUseCase: playerUseCase)
        }
        ctner.register(WithdrawalCryptoRequestViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepositoryImpl.self)!
            return WithdrawalCryptoRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerUseCase: playerUseCase, localStorageRepository: repoLocalStorage)
        }
        ctner.register(CasinoViewModel.self) { (resolver) in
            return CasinoViewModel(casinoRecordUseCase: ctner.resolve(CasinoRecordUseCase.self)!, casinoUseCase: ctner.resolve(CasinoUseCase.self)!, memoryCache: MemoryCacheImpl.shared)
        }
        ctner.register(SlotViewModel.self) { (resolver) in
            return SlotViewModel(slotUseCase: ctner.resolve(SlotUseCase.self)!)
        }
        ctner.register(SlotBetViewModel.self) { (resolver) in
            return SlotBetViewModel(slotUseCase: ctner.resolve(SlotUseCase.self)!, slotRecordUseCase: ctner.resolve(SlotRecordUseCase.self)!)
        }
        ctner.register(NumberGameViewModel.self) { (resolver) in
            return NumberGameViewModel(numberGameUseCase: ctner.resolve(NumberGameUseCase.self)!, memoryCache: MemoryCacheImpl.shared)
        }
        ctner.register(NumberGameRecordViewModel.self) { (resolver) in
            return NumberGameRecordViewModel(numberGameRecordUseCase: ctner.resolve(NumberGameRecordUseCase.self)!)
        }
        ctner.register(CryptoVerifyViewModel.self) { (resolver) in
            return CryptoVerifyViewModel(playerUseCase: ctner.resolve(PlayerDataUseCase.self)!, withdrawalUseCase:  ctner.resolve(WithdrawalUseCase.self)!, systemUseCase: ctner.resolve(GetSystemStatusUseCase.self)!)
        }
        ctner.register(P2PViewModel.self) { (resolver) in
            return P2PViewModel(p2pUseCase: ctner.resolve(P2PUseCase.self)!)
        }
        ctner.register(P2PBetViewModel.self) { (resolver) in
            return P2PBetViewModel(p2pRecordUseCase: ctner.resolve(P2PRecordUseCase.self)!)
        }
        ctner.register(ArcadeRecordViewModel.self) { (resolver) in
            return ArcadeRecordViewModel(arcadeRecordUseCase: ctner.resolve(ArcadeRecordUseCase.self)!)
        }
        ctner.register(ArcadeViewModel.self) { (resolver) in
            return ArcadeViewModel(arcadeUseCase: ctner.resolve(ArcadeUseCase.self)!, memoryCache: MemoryCacheImpl.shared)
        }
        ctner.register(PromotionViewModel.self) { (resolver) in
            return PromotionViewModel(promotionUseCase: ctner.resolve(PromotionUseCase.self)!, playerUseCase: ctner.resolve(PlayerDataUseCase.self)!)
        }
        ctner.register(PromotionHistoryViewModel.self) { (resolver) in
            return PromotionHistoryViewModel(promotionUseCase: ctner.resolve(PromotionUseCase.self)!)
        }
        ctner.register(TransactionLogViewModel.self) { (resolver) in
            return TransactionLogViewModel(transactionLogUseCase: ctner.resolve(TransactionLogUseCase.self)!)
        }
        ctner.register(CustomerServiceViewModel.self) { (resolver) in
            return CustomerServiceViewModel(customerServiceUseCase: ctner.resolve(CustomerServiceUseCase.self)!)
        }
        ctner.register(SurveyViewModel.self) { (resolver) in
            return SurveyViewModel(ctner.resolve(CustomerServiceSurveyUseCase.self)!, ctner.resolve(AuthenticationUseCase.self)!)
        }
        ctner.register(CustomerServiceHistoryViewModel.self) { (resolver) in
            return CustomerServiceHistoryViewModel(historyUseCase: ctner.resolve(ChatRoomHistoryUseCase.self)!)
        }
        ctner.register(TermsViewModel.self) { (resolver) in
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            return TermsViewModel(localizationPolicyUseCase: ctner.resolve(LocalizationPolicyUseCase.self)!, systemStatusUseCase: systemUseCase)
        }
        ctner.register(ModifyProfileViewModel.self) { (resolver) in
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let pattern = ctner.resolve(AccountPatternGenerator.self)!
            return ModifyProfileViewModel(playerUseCase, usecaseConfiguration, withdrawalUseCase, pattern)
        }
        ctner.register(CommonOtpViewModel.self) { (resolver) in
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            return CommonOtpViewModel(usecaseConfiguration)
        }
        ctner.register(ConfigurationViewModel.self) { (resolver) in
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            return ConfigurationViewModel(usecaseConfiguration)
        }
        ctner.register(AppSynchronizeViewModel.self) { (resolver) in
            let appUpdateUseCase = ctner.resolve(AppVersionUpdateUseCase.self)!
            return AppSynchronizeViewModel(appUpdateUseCase: appUpdateUseCase)
        }.inObjectScope(.application)
        ctner.register(StarMergerViewModel.self) { (resolver) in
            let applicationFactory = ctner.resolve(ApplicationFactory.self)!
            let depositService = applicationFactory.deposit()
            return StarMergerViewModel(depositService: depositService)
        }
    }
    
    func registLoginView(){
        
//        let ctner = container
//        let httpclient = httpClient
//        let story = UIStoryboard(name: "Login", bundle: nil)
//        let viewModel = ctner.resolve(LoginViewModel.self)!
//
//        ctner.register(LoginViewController.self) { (resolve)  in
//            let identifier = String(describing: LoginViewController.self )
//            return story.instantiateViewController(identifier: identifier) { (coder) -> LoginViewController in
//                return LoginViewController.init(coder: coder)
//            }
//        }
    }
    
    func registSignupView(){
        
//        let ctner = container
//        let httpclient = httpClient
//        let story = UIStoryboard(name: "Login", bundle: nil)
    }
}

extension ObjectScope {
    static let application = ObjectScope(storageFactory: PermanentStorage.init)
    static let lobby = ObjectScope(storageFactory: PermanentStorage.init)
    static let landing = ObjectScope(storageFactory: PermanentStorage.init)
    static let depositFlow = ObjectScope(storageFactory: PermanentStorage.init)
}
