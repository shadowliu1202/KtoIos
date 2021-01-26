import Foundation
import RxSwift
import share_bu

protocol PlayerDataUseCase {
    func getBalance() -> Single<CashAmount>
    func setBalanceHiddenState(gameId: String, isHidden: Bool)
    func getBalanceHiddenState(gameId: String) -> Bool
    func loadPlayer() -> Single<Player>
}

class PlayerDataUseCaseImpl: PlayerDataUseCase {
    var playerRepository : PlayerRepository!
    var localRepository: LocalStorageRepository!
    
    init(_ playerRepository : PlayerRepository, localRepository: LocalStorageRepository) {
        self.playerRepository = playerRepository
        self.localRepository = localRepository
    }
    
    func getBalance() -> Single<CashAmount> {
        return self.playerRepository.getBalance()
    }
    
    func setBalanceHiddenState(gameId: String, isHidden: Bool) {
        localRepository.setBalanceHiddenState(isHidden: isHidden, gameId: gameId)
    }

    func getBalanceHiddenState(gameId: String) -> Bool {
        return localRepository.getBalanceHiddenState(gameId: gameId)
    }

    func loadPlayer() -> Single<Player> {
        return playerRepository.loadPlayer()
    }
}
