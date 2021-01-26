//
//  DIContainer.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/22.
//

import Foundation
import Swinject
import share_bu

public let DI = DIContainer.share.container

class DIContainer {
    
    static let share = DIContainer()
    let container = Container()
    let httpClient = HttpClient()
    
    init() {
        registApi()
        registRepo()
        registUsecase()
        registViewModel()
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
        ctner.register(PlayerViewModel.self) { (resolver) in
            let playerUseCase = ctner.resolve(PlayerDataUseCase.self)!
            let authUseCase = ctner.resolve(AuthenticationUseCase.self)!
            return PlayerViewModel(playerUseCase: playerUseCase, authUsecase: authUseCase)
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
