import Foundation
import RxSwift
import SharedBu

class LaunchViewModel {
    var authUseCase: AuthenticationUseCase!
    private var playerUseCase : PlayerDataUseCase!
    private var localizationPolicyUseCase: LocalizationPolicyUseCase!
    
    init(_ authUseCase: AuthenticationUseCase, playerUseCase: PlayerDataUseCase, localizationPolicyUseCase: LocalizationPolicyUseCase) {
        self.authUseCase = authUseCase
        self.playerUseCase = playerUseCase
        self.localizationPolicyUseCase = localizationPolicyUseCase
    }
    
    func checkIsLogged() -> Single<Bool>{
        authUseCase.isLogged()
    }
    
    func loadPlayerInfo() -> Single<Player> {
        playerUseCase.loadPlayer()
    }
    
    func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
}
