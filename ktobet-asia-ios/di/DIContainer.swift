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
        
        ctner.register(IPlayerRepository.self) { (resolver) in
            let player = ctner.resolve(PlayerApi.self)!
            let portal = ctner.resolve(PortalApi.self)!
            return IPlayerRepositoryImpl(player, portal)
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
    }
    
    func registUsecase(){
        
        let ctner = container
        
        ctner.register(IRegisterUseCase.self) { (resolver)  in
            let auth = ctner.resolve(IAuthRepository.self)!
            let player = ctner.resolve(IPlayerRepository.self)!
            return IRegisterUseCaseImpl(auth, player)
        }
        ctner.register(IConfigurationUseCase.self) { (resolver) in
            let repo = ctner.resolve(IPlayerRepository.self)!
            return IConfigurationUseCaseImpl.init(repo)
        }
        ctner.register(IAuthenticationUseCase.self) { (resolver)  in
            let repoAuth = ctner.resolve(IAuthRepository.self)!
            let repoPlayer = ctner.resolve(IPlayerRepository.self)!
            return IAuthenticationUseCaseImpl(repoAuth, repoPlayer)
        }
        ctner.register(GetSystemStatusUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemRepository.self)!
            return GetSystemStatusUseCaseImpl(repoSystem)
        }
        ctner.register(ResetPasswordUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(ResetPasswordRepository.self)!
            return ResetPasswordUseCaseImpl(repoSystem)
        }
        ctner.register(SystemSignalRUseCase.self) { (resolver)  in
            let repoSystem = ctner.resolve(SystemSignalRepository.self)!
            return SystemSignalRUseCaseImpl(repoSystem)
        }
        
    }
    
    func registViewModel(){
        
        let ctner = container
        let httpclient = httpClient
        
        ctner.register(LaunchViewModel.self) { (resolver)  in
            let usecaseAuth = ctner.resolve(IAuthenticationUseCase.self)!
            return LaunchViewModel(usecaseAuth )
        }
        ctner.register(LobbyViewModel.self) { (resolver) in
            let usecaseAuth = ctner.resolve(IAuthenticationUseCase.self)!
            let usecaseConfig = ctner.resolve(IConfigurationUseCase.self)!
            return LobbyViewModel.init(usecaseAuth, usecaseConfig)
        }
        ctner.register(TestViewModel.self) { (resolver) in
            let gameRepo = ctner.resolve(GameInfoRepository.self)!
            let csRepo = ctner.resolve(CustomServiceRepository.self)!
            return TestViewModel(gameRepo, csRepo, httpclient)
        }
        ctner.register(LoginViewModel.self) { resolver  in
            let usecaseAuthentication = ctner.resolve(IAuthenticationUseCase.self)!
            let usecaseConfiguration = ctner.resolve(IConfigurationUseCase.self)!
            return LoginViewModel(usecaseAuthentication, usecaseConfiguration)
        }
        ctner.register(SignupUserInfoViewModel.self){ resolver in
            let registerUseCase = ctner.resolve(IRegisterUseCase.self)!
            let systemUseCase = ctner.resolve(GetSystemStatusUseCase.self)!
            return SignupUserInfoViewModel(registerUseCase, systemUseCase)
        }
        ctner.register(SignupPhoneViewModel.self) { resolver in
            let usecase = ctner.resolve(IRegisterUseCase.self)!
            return SignupPhoneViewModel(usecase)
        }
        ctner.register(SignupEmailViewModel.self) { resolver in
            let usecaseRegister = ctner.resolve(IRegisterUseCase.self)!
            let usecaseConfiguration = ctner.resolve(IConfigurationUseCase.self)!
            let usecaseAuthentication = ctner.resolve(IAuthenticationUseCase.self)!
            return SignupEmailViewModel(usecaseRegister, usecaseConfiguration, usecaseAuthentication)
        }
        ctner.register(DefaultProductViewModel.self) { resolver in
            let usecase = ctner.resolve(IConfigurationUseCase.self)!
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
    }
}
