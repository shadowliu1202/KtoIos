import Foundation
import RxSwift
import share_bu

class PlayerViewModel {
    private var playerUseCase : PlayerDataUseCase!
    private var authUsecase : AuthenticationUseCase!
    
    var balance: String?
                
    init(playerUseCase: PlayerDataUseCase, authUsecase: AuthenticationUseCase) {
        self.playerUseCase = playerUseCase
        self.authUsecase = authUsecase
    }
        
    func getBalance() -> Observable<String> {
        return self.playerUseCase.getBalance().map{ $0.amount.currencyFormat() }.asObservable()
    }
    
    func loadPlayerInfo() -> Observable<Player> {
        return self.playerUseCase.loadPlayer().asObservable()
    }
    
    func getBalanceHiddenState(gameId: String) -> Bool {
        return self.playerUseCase.getBalanceHiddenState(gameId: gameId)
    }
    
    func saveBalanceHiddenState(gameId: String, isHidden: Bool) {
        self.playerUseCase.setBalanceHiddenState(gameId: gameId, isHidden: isHidden)
    }
    
    func logout() -> Completable {
        return authUsecase.logout()
    }
}
