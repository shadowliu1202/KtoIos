import Foundation
import RxSwift
import share_bu

class PlayerViewModel {
    private var playerUseCase : PlayerDataUseCase!
    private var authUsecase : IAuthenticationUseCase!
    
    var balance: String?
                
    init(playerUseCase: PlayerDataUseCase, authUsecase: IAuthenticationUseCase) {
        self.playerUseCase = playerUseCase
        self.authUsecase = authUsecase
    }
        
    func getBalance() -> Observable<String> {
        return self.playerUseCase.getBalance().map{ $0.amount.currencyFormat() }.asObservable()
    }
    
    func getBalanceHiddenState(gameId: String) -> Bool {
        return self.playerUseCase.getBalanceHiddenState(gameId: gameId)
    }
    
    func saveBalanceHiddenState(gameId: String, isHidden: Bool) {
        self.playerUseCase.saveBalanceHiddenState(gameId: gameId, isHidden: isHidden)
    }
    
    func logout() -> Completable {
        return authUsecase.logout()
    }
}
