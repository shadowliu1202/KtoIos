import Foundation
import RxSwift
import share_bu

protocol PlayerDataUseCase {
    func getBalance() -> Single<CashAmount>
    func saveBalanceHiddenState(gameId: String, isHidden: Bool)
    func getBalanceHiddenState(gameId: String) -> Bool
    func loadPlayer() -> Single<Player>
}

class PlayerDataUseCaseImpl: PlayerDataUseCase {
    var playerRepository : PlayerRepository!
    
    init(_ playerRepository : PlayerRepository) {
        self.playerRepository = playerRepository
    }
    
    func getBalance() -> Single<CashAmount> {
        return self.playerRepository.getBalance()
    }
    
    func saveBalanceHiddenState(gameId: String, isHidden: Bool) {
        UserDefaults.standard.setValue(isHidden, forKey: gameId)
    }

    func getBalanceHiddenState(gameId: String) -> Bool {
        return (UserDefaults.standard.object(forKey: gameId) as? Bool) ?? false
    }

    func loadPlayer() -> Single<Player> {
        return playerRepository.loadPlayer()
    }
}
