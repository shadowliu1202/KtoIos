import Foundation
import RxSwift
import SharedBu

class PlayerViewModel {
    private var playerUseCase : PlayerDataUseCase!
    private var authUsecase : AuthenticationUseCase!
    
    var balance: String?
    var refreshBalance = PublishSubject<(Void)>()
    lazy var playerBalance = refreshBalance.flatMapLatest{_ in
        self.playerUseCase.getBalance()
            .map{ $0.amount.floor(toDecimal: 2).currencyFormat() }
            .asObservable()
    }
                
    init(playerUseCase: PlayerDataUseCase, authUsecase: AuthenticationUseCase) {
        self.playerUseCase = playerUseCase
        self.authUsecase = authUsecase
    }
        
    func getBalance() -> Observable<String> {
        return self.playerUseCase.getBalance().map{ $0.amount.floor(toDecimal: 2).currencyFormat() }.asObservable()
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
    
    func getPrivilege() -> Single<[LevelOverview]> {
        playerUseCase.getPrivilege()
    }
    
    func logout() -> Completable {
        return authUsecase.logout()
    }
}
