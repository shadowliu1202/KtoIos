import Foundation
import RxSwift
import share_bu

class LaunchViewModel {
    
    var authUseCase: AuthenticationUseCase!
    private var playerUseCase : PlayerDataUseCase!
    
    init(_ authUseCase: AuthenticationUseCase, playerUseCase: PlayerDataUseCase) {
        self.authUseCase = authUseCase
        self.playerUseCase = playerUseCase
    }
    
    func checkIsLogged() -> Single<Bool>{
        return authUseCase.isLogged()
    }
    
    func loadPlayerInfo() -> Single<Player> {
        return self.playerUseCase.loadPlayer()
    }
}
