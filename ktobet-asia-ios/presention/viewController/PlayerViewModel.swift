import Foundation
import RxSwift
import SharedBu

class PlayerViewModel {
    private var playerUseCase : PlayerDataUseCase!
    private var authUsecase : AuthenticationUseCase!
    
    private(set) var balance: String?
    var refreshBalance = PublishSubject<(Void)>()
    lazy var playerBalance = refreshBalance.flatMapLatest{_ in
        self.playerUseCase.getBalance()
            .map { $0.toAccountCurrency().symbol + " " + $0.toAccountCurrency().formatString() }
            .do(onSuccess: { self.balance = $0 })
    }.asDriver(onErrorJustReturn: "")
                
    init(playerUseCase: PlayerDataUseCase, authUsecase: AuthenticationUseCase) {
        self.playerUseCase = playerUseCase
        self.authUsecase = authUsecase
    }
    
    func loadPlayerInfo() -> Observable<Player> {
        playerUseCase.loadPlayer().asObservable()
    }
    
    func getBalanceHiddenState(gameId: String) -> Bool {
        playerUseCase.getBalanceHiddenState(gameId: gameId)
    }
    
    func saveBalanceHiddenState(gameId: String, isHidden: Bool) {
        playerUseCase.setBalanceHiddenState(gameId: gameId, isHidden: isHidden)
    }
    
    func getPrivilege() -> Single<[LevelOverview]> {
        playerUseCase.getPrivilege()
    }
    
    func logout() -> Completable {
        authUsecase.logout()
    }
    
    func checkIsLogged() -> Single<Bool>{
        authUsecase.isLogged()
    }
}
