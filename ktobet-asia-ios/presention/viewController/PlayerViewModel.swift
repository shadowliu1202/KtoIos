import Foundation
import RxSwift
import SharedBu
import RxCocoa

class PlayerViewModel: CollectErrorViewModel {
    
    private let playerUseCase: PlayerDataUseCase
    private let authUseCase: AuthenticationUseCase
                
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
        CustomServicePresenter.shared.closeService()
            .concat(
                authUseCase.logout()
            )
            .do(onCompleted: {
                Injectable.resetObjectScope(.locale)
            })
    }
    
    func checkIsLogged() -> Single<Bool>{
        authUseCase.isLogged()
    }
    
    func getPlayerInfo() -> Driver<Player?> {
        playerUseCase.loadPlayer()
            .map { $0 }
            .asDriver(onErrorRecover: { [weak self] error in
                self?.errorsSubject.onNext(error)
                
                return .just(nil)
            })
    }
    
    func getBalance() -> Driver<AccountCurrency?> {
        playerUseCase.getBalance()
            .map { $0 }
            .asDriver(onErrorRecover: { [weak self] error in
                self?.errorsSubject.onNext(error)
                
                return .just(nil)
            })
    }
}

enum AuthenticationState {
    case unauthenticated        // Initial state, the user needs to authenticate
    case authenticated          // The user has authenticated successfully
}
