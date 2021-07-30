import Foundation
import RxSwift
import SharedBu

protocol PlayerDataUseCase {
    func getBalance() -> Single<CashAmount>
    func setBalanceHiddenState(gameId: String, isHidden: Bool)
    func getBalanceHiddenState(gameId: String) -> Bool
    func loadPlayer() -> Single<Player>
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<[String: Double]>
    func isRealNameEditable() -> Single<Bool>
    func getPrivilege() -> Single<[LevelOverview]>
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
        return playerRepository.loadPlayer().do(onSuccess: { [weak self] (player) in
            self?.localRepository.setCultureCode(player.locale().cultureCode())
        })
    }
    
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<[String: Double]> {
        return playerRepository.getCashLogSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType)
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerRepository.isRealNameEditable()
    }
    
    func getPrivilege() -> Single<[LevelOverview]> {
        return playerRepository.getLevelPrivileges()
    }
}
