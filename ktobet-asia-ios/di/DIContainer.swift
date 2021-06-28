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
    lazy var httpClient = container.resolve(HttpClient.self)!
    
    private init() {
        registerHttpClient()
        registApi()
        registRepo()
        registUsecase()
        registViewModel()
    }
    
    func registerHttpClient() {
        let ctner = container
        ctner.register(HttpClient.self) { (resolver)  in
            return HttpClient()
        }
    }
    
    func registApi() {
        
        let ctner = container
        let httpclient = httpClient
        
        ctner.register(AuthenticationApi.self) { (resolver)  in
            return AuthenticationApi(httpclient)
        }
        ctner.register(PlayerApi.self) { (resolver)  in
            return PlayerApi(httpclient)
        }
        ctner.register(PortalApi.self) { (resolver) in
            return PortalApi(httpclient)
        }
        ctner.register(GameApi.self) { (resolver)  in
            return GameApi(httpclient)
        }
        ctner.register(CustomServiceApi.self) { (resolver) in
            return CustomServiceApi(httpclient)
        }
        ctner.register(BankApi.self) { (resolver) in
            return BankApi(httpclient)
        }
        ctner.register(ImageApi.self) { (resolver) in
            return ImageApi(httpclient)
        }
        ctner.register(CasinoApi.self) { (resolver) in
            return CasinoApi(httpclient)
        }
        ctner.register(SlotApi.self) { (resolver) in
            return SlotApi(httpclient)
        }
        ctner.register(NumberGameApi.self) { (resolver) in
            return NumberGameApi(httpclient)
        }
        ctner.register(CPSApi.self) { (resolver) in
            return CPSApi(httpclient)
        }
    }
    
    func registRepo(){
        
        let ctner = container
        let httpclient = httpClient
        
        ctner.register(PlayerRepository.self) { (resolver) in
            let player = ctner.resolve(PlayerApi.self)!
            let portal = ctner.resolve(PortalApi.self)!
            return PlayerRepositoryImpl(player, portal)
        }
        ctner.register(GameInfoRepository.self) { (resolver) in
            let gameApi = ctner.resolve(GameApi.self)!
            return GameInfoRepositoryImpl(gameApi, httpclient)
        }
        ctner.register(CustomServiceRepository.self) { (resolver) in
            let csApi = ctner.resolve(CustomServiceApi.self)!
            return CustomServiceRepositoryImpl(csApi, httpclient)
        }
        ctner.register(IAuthRepository.self) { resolver in
            let api = ctner.resolve(AuthenticationApi.self)!
            return IAuthRepositoryImpl( api, httpclient)
        }
        ctner.register(SystemRepository.self) { resolver in
            let api = ctner.resolve(PortalApi.self)!
            return SystemRepositoryImpl(api)
        }
        ctner.register(ResetPasswordRepository.self) { resolver in
            let api = ctner.resolve(AuthenticationApi.self)!
            return IAuthRepositoryImpl(api, httpclient)
        }
        ctner.register(SystemSignalRepository.self) { resolver in
            return SystemSignalRepositoryImpl(httpclient)
        }
        ctner.register(LocalStorageRepository.self) { resolver in
            return LocalStorageRepository()
        }
        ctner.register(DepositRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            let imageApi = ctner.resolve(ImageApi.self)!
            let cpsApi = ctner.resolve(CPSApi.self)!
            return DepositRepositoryImpl(bankApi, imageApi: imageApi, cpsApi: cpsApi)
        }
        ctner.register(ImageRepository.self) { resolver in
            let imageApi = ctner.resolve(ImageApi.self)!
            return ImageRepositoryImpl(imageApi)
        }
        ctner.register(WithdrawalRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            let imageApi = ctner.resolve(ImageApi.self)!
            let cpsApi = ctner.resolve(CPSApi.self)!
            return WithdrawalRepositoryImpl(bankApi, imageApi: imageApi, cpsApi: cpsApi)
        }
        ctner.register(BankRepository.self) { resolver in
            let bankApi = ctner.resolve(BankApi.self)!
            return BankRepositoryImpl(bankApi)
        }
        ctner.register(CasinoRecordRepository.self) { resolver in
            let casinoApi = ctner.resolve(CasinoApi.self)!
            return CasinoRecordRepositoryImpl(casinoApi)
        }
        ctner.register(CasinoRepository.self) { resolver in
            let casinoApi = ctner.resolve(CasinoApi.self)!
            return CasinoRepositoryImpl(casinoApi)
        }
        ctner.register(SlotRepository.self) { resolver in
            let slotApi = ctner.resolve(SlotApi.self)!
            return SlotRepositoryImpl(slotApi)
        }
        ctner.register(SlotRecordRepository.self) { resolver in
            let slotApi = ctner.resolve(SlotApi.self)!
            return SlotRecordRepositoryImpl(slotApi)
        }
        ctner.register(NumberGameRepository.self) { (resolver) in
            let numberGameApi = ctner.resolve(NumberGameApi.self)!
            return NumberGameRepositoryImpl(numberGameApi)
        }
        ctner.register(NumberGameRecordRepository.self) { (resolver) in
            let numberGameApi = ctner.resolve(NumberGameApi.self)!
            return NumberGameRecordRepositoryImpl(numberGameApi)
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
            return ConfigurationUseCaseImpl.init(repo)
        }
        ctner.register(AuthenticationUseCase.self) { (resolver)  in
            let repoAuth = ctner.resolve(IAuthRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepository.self)!
            return AuthenticationUseCaseImpl(repoAuth, repoPlayer, repoLocalStorage)
        }
        ctner.register(GetSystemStatusUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemRepository.self)!
            return GetSystemStatusUseCaseImpl(repoSystem)
        }
        ctner.register(ResetPasswordUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(ResetPasswordRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepository.self)!
            return ResetPasswordUseCaseImpl(repoSystem, localRepository: repoLocal)
        }
        ctner.register(SystemSignalRUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemSignalRepository.self)!
            return SystemSignalRUseCaseImpl(repoSystem)
        }
        ctner.register(PlayerDataUseCase.self) { (resolver)  in
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepository.self)!
            return PlayerDataUseCaseImpl(repoPlayer, localRepository: repoLocal)
        }
        ctner.register(DepositUseCase.self) { (resolver)  in
            let repoDeposit = ctner.resolve(DepositRepository.self)!
            return DepositUseCaseImpl(repoDeposit)
        }
        ctner.register(UploadImageUseCase.self) { (resolver)  in
            let repoImage = ctner.resolve(ImageRepository.self)!
            return UploadImageUseCaseImpl(repoImage)
        }
        ctner.register(WithdrawalUseCase.self) { (resolver)  in
            let repoWithdrawal = ctner.resolve(WithdrawalRepository.self)!
            return WithdrawalUseCaseImpl(repoWithdrawal)
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
            let repoLocal = ctner.resolve(LocalStorageRepository.self)!
            return CasinoUseCaseImpl(repo, repoLocal)
        }
        ctner.register(SlotUseCase.self) { (resolver) in
            let repo = ctner.resolve(SlotRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepository.self)!
            return SlotUseCaseImpl(repo, repoLocal)
        }
        ctner.register(SlotRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(SlotRecordRepository.self)!
            let repoPlayer = ctner.resolve(PlayerRepository.self)!
            return SlotRecordUseCaseImpl(repo, playerRepository: repoPlayer)
        }
        ctner.register(NumberGameUseCase.self) { (resolver) in
            let repo = ctner.resolve(NumberGameRepository.self)!
            let repoLocal = ctner.resolve(LocalStorageRepository.self)!
            return NumberGameUseCasaImp(repo, repoLocal)
        }
        ctner.register(NumberGameRecordUseCase.self) { (resolver) in
            let repo = ctner.resolve(NumberGameRecordRepository.self)!
            return NumberGameRecordUseCaseImpl(numberGameRecordRepository: repo)
        }
    }
    
    func registViewModel(){
        
        let ctner = container
        let httpclient = httpClient
        
        ctner.register(LaunchViewModel.self) { (resolver)  in
            let usecaseAuth = ctner.resolve(AuthenticationUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            return LaunchViewModel(usecaseAuth, playerUseCase: playerUseCase)
        }
        ctner.register(TestViewModel.self) { (resolver) in
            let gameRepo = ctner.resolve(GameInfoRepository.self)!
            let csRepo = ctner.resolve(CustomServiceRepository.self)!
            return TestViewModel(gameRepo, csRepo, httpclient)
        }
        ctner.register(LoginViewModel.self) { resolver  in
            let usecaseAuthentication = ctner.resolve(AuthenticationUseCase.self)!
            let usecaseConfiguration = ctner.resolve(ConfigurationUseCase.self)!
            return LoginViewModel(usecaseAuthentication, usecaseConfiguration)
        }
        ctner.register(SignupUserInfoViewModel.self){ resolver in
            let registerUseCase = ctner.resolve(RegisterUseCase.self)!
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            return SignupUserInfoViewModel(registerUseCase, systemUseCase)
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
            return ResetPasswordViewModel(usecaseAuthentication, systemUseCase)
        }
        ctner.register(SystemViewModel.self) { (resolver) in
            let sstemSignalRUseCase = ctner.resolve(SystemSignalRUseCase.self)!
            return SystemViewModel(systemUseCase: sstemSignalRUseCase)
        }
        ctner.register(ServiceStatusViewModel.self) { resolver  in
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            return ServiceStatusViewModel(usecaseSystemStatus: systemUseCase)
        }
        ctner.register(PlayerViewModel.self) { (resolver) in
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let authUseCase = ctner.resolve(AuthenticationUseCase.self)!
            return PlayerViewModel(playerUseCase: playerUseCase, authUsecase: authUseCase)
        }
        ctner.register(DepositViewModel.self) { (resolver) in
            let depositUseCase = ctner.resolve(DepositUseCase.self)!
            let authUseCase = ctner.resolve(AuthenticationUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let bankUseCase = ctner.resolve(BankUseCase.self)!
            return DepositViewModel(depositUseCase: depositUseCase, usecaseAuth: authUseCase, playerUseCase: playerUseCase, bankUseCase: bankUseCase)
        }
        ctner.register(UploadPhotoViewModel.self) { (resolver) in
            let imageUseCase = ctner.resolve(UploadImageUseCase.self)!
            return UploadPhotoViewModel(imageUseCase: imageUseCase)
        }
        ctner.register(WithdrawalViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let repoLocalStorage = ctner.resolve(LocalStorageRepository.self)!
            return WithdrawalViewModel(withdrawalUseCase: withdrawalUseCase, localStorageRepository: repoLocalStorage)
        }
        ctner.register(ManageCryptoBankCardViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            return ManageCryptoBankCardViewModel(withdrawalUseCase: withdrawalUseCase)
        }
        ctner.register(AddBankViewModel.self) { (resolver) in
            return AddBankViewModel(ctner.resolve(AuthenticationUseCase.self)!,
                                    ctner.resolve(BankUseCase.self)!,
                                    ctner.resolve(WithdrawalUseCase.self)!,
                                    ctner.resolve(PlayerDataUseCase.self)!)
        }
        ctner.register(WithdrawlLandingViewModel.self) { (resolver) in
            return WithdrawlLandingViewModel(ctner.resolve(WithdrawalUseCase.self)!)
        }
        ctner.register(WithdrawalRequestViewModel.self) { (resolver) in
            let withdrawalUseCase = ctner.resolve(WithdrawalUseCase.self)!
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            return WithdrawalRequestViewModel(withdrawalUseCase: withdrawalUseCase, playerDataUseCase: playerUseCase)
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
