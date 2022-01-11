import Foundation
import RxSwift
import SharedBu

protocol PlayerDataUseCase {
    func getBalance() -> Single<AccountCurrency>
    func setBalanceHiddenState(gameId: String, isHidden: Bool)
    func getBalanceHiddenState(gameId: String) -> Bool
    func loadPlayer() -> Single<Player>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]>
    func isRealNameEditable() -> Single<Bool>
    func getPrivilege() -> Single<[LevelOverview]>
    func getSupportLocalFromCache() -> SupportLocale
    func getPlayerRealName() -> Single<String>
    func isAffiliateMember() -> Single<Bool>
}

class PlayerDataUseCaseImpl: PlayerDataUseCase {
    var playerRepository : PlayerRepository!
    var localRepository: LocalStorageRepository!
    var settingStore: SettingStore!
    
    init(_ playerRepository : PlayerRepository, localRepository: LocalStorageRepository, settingStore: SettingStore) {
        self.playerRepository = playerRepository
        self.localRepository = localRepository
        self.settingStore = settingStore
    }
    
    func getBalance() -> Single<AccountCurrency> {
        return self.playerRepository.getBalance(localRepository.getSupportLocal())
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
    
    func getPlayerRealName() -> Single<String> {
        playerRepository.getPlayerRealName()
    }
    
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]> {
        return playerRepository.getCashLogSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType)
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerRepository.isRealNameEditable()
    }
    
    func getPrivilege() -> Single<[LevelOverview]> {
        return playerRepository.getLevelPrivileges()
    }
    
    func getSupportLocalFromCache() -> SupportLocale {
        return localRepository.getSupportLocal()
    }
    
    func isAffiliateMember() -> Single<Bool> {
        return playerRepository.getAffiliateStatus().map({ $0 == AffiliateApplyStatus.applied })
    }
}
