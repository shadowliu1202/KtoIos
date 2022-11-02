import Foundation
import RxSwift
import SharedBu

class PlayerViewModel {
    
    private let playerUseCase: PlayerDataUseCase
    private let authUseCase: AuthenticationUseCase
    
    private(set) var balance: String?

    lazy var playerBalance = refreshBalance.flatMapLatest{_ in
        self.playerUseCase.getBalance()
            .map { "\($0.symbol) \($0.formatString())" }
            .do(onSuccess: { self.balance = $0 })
    }.asDriver(onErrorJustReturn: "")

    var refreshBalance = PublishSubject<(Void)>()
                
    init(playerUseCase: PlayerDataUseCase, authUseCase: AuthenticationUseCase) {
        self.playerUseCase = playerUseCase
        self.authUseCase = authUseCase
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
        authUseCase.logout()
            .do(afterCompleted: {
                DI.resetObjectScope(.locale)
            })
    }
    
    func checkIsLogged() -> Single<Bool>{
        authUseCase.isLogged()
    }
}

enum AuthenticationState {
    case unauthenticated        // Initial state, the user needs to authenticate
    case authenticated          // The user has authenticated successfully
}
