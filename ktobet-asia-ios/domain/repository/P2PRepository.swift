import Foundation
import RxSwift
import SharedBu


protocol P2PRepository {
    func getTurnOverStatus() -> Single<P2PTurnOver>
    func getAllGames() -> Single<[P2PGame]>
    func createGame(gameId: Int32) -> Single<URL?>
}

class P2PRepositoryImpl: P2PRepository {
    private var p2pApi: P2PApi!
    
    init(_ p2pApi: P2PApi) {
        self.p2pApi = p2pApi
    }
    
    func getTurnOverStatus() -> Single<P2PTurnOver> {
        return self.p2pApi.checkBonusLockStatus().map { (response) -> P2PTurnOver in
            guard let data = response.data else { return P2PTurnOver.init() }
            if !data.bonusLocked && !data.hasBonusTag {
                return P2PTurnOver.None.init()
            } else if data.bonusLocked && data.hasBonusTag {
                guard let currentBonus = data.currentBonus else {
                    return P2PTurnOver.Calculating.init()
                }
                return self.convertToTurnOverReceipt(bean: currentBonus)
            } else {
                return P2PTurnOver.Calculating.init()
            }
        }
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        return p2pApi.getAllGames().map { (response) -> [P2PGame] in
            guard let data = response.data else { return [] }
            return data.map { (bean) -> P2PGame in
                P2PGame.init(gameId: bean.gameId, gameName: bean.name, isFavorite: false, gameStatus: GameStatus.Companion.init().convert(gameMaintenance: false, status: bean.status), thumbnail: P2PThumbnail.init(host: KtoURL.baseUrl.absoluteString, thumbnailId: bean.imageId))
            }
        }
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return p2pApi.getGameUrl(gameId: gameId, siteUrl: KtoURL.baseUrl.absoluteString).map { (response) -> URL? in
            guard let data = response.data else { return nil }
            return URL(string: data)
        }
    }
    
    private func convertToTurnOverReceipt(bean: LockedBonusDataBean) -> P2PTurnOver.TurnOverReceipt {
        let informPlayerDate = bean.informPlayerDate.convertDateTime() ?? Date()
        let informPlayerLocalDate =  Kotlinx_datetimeLocalDate.init(year: informPlayerDate.getYear(), monthNumber: informPlayerDate.getMonth(), dayOfMonth: informPlayerDate.getDayOfMonth())
        return P2PTurnOver.TurnOverReceipt.init(turnOverDetail: TurnOverDetail.init(achieved: bean.achieved, formula: bean.formula, informPlayerDate: informPlayerLocalDate, name: bean.name, bonusId: bean.no, remainAmount: CashAmount(amount: bean.remainingAmount.currencyAmountToDouble() ?? 0), parameters: TurnOverDetail.Parameters.init(amount: CashAmount(amount: bean.parameters.amount.currencyAmountToDouble() ?? 0), balance: bean.parameters.balance, betMultiplier: "\(bean.parameters.betMultiplier)", capital: bean.parameters.capital, depositRequest: bean.parameters.depositRequest, percentage: Double(bean.parameters.percentage) ?? 0, request: bean.parameters.request, requirement: bean.parameters.requirement, turnoverRequest: CashAmount(amount: bean.parameters.turnoverRequest.currencyAmountToDouble() ?? 0))))
    }
}

