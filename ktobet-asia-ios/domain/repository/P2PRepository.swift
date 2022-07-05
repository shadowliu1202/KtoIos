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
    private var httpClient: HttpClient!
    
    init(_ p2pApi: P2PApi, httpClient: HttpClient) {
        self.p2pApi = p2pApi
        self.httpClient = httpClient
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
                return try self.convertToTurnOverReceipt(bean: currentBonus)
            } else {
                return P2PTurnOver.Calculating.init()
            }
        }
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        return p2pApi.getAllGames().map { (response) -> [P2PGame] in
            guard let data = response.data else { return [] }
            return data.map { [unowned self] (bean) -> P2PGame in
                P2PGame.init(gameId: bean.gameId, gameName: bean.name, isFavorite: false, gameStatus: GameStatus.Companion.init().convert(gameMaintenance: false, status: bean.status), thumbnail: P2PThumbnail.init(host: self.httpClient.host.absoluteString, thumbnailId: bean.imageId))
            }
        }
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return p2pApi.getGameUrl(gameId: gameId, siteUrl: httpClient.host.absoluteString).map { (response) -> URL? in
            guard let data = response.data else { return nil }
            return URL(string: data)
        }.catchException(transferLogic: {
            if $0 is GameUnderMaintenance {
                return KtoGameUnderMaintenance()
            }
            return $0
        })
    }
    
    private func convertToTurnOverReceipt(bean: LockedBonusDataBean) throws -> P2PTurnOver.TurnOverReceipt {
        return try bean.toTurnOverReceipt()
    }
}

