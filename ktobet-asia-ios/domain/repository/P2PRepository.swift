import Foundation
import RxSwift
import SharedBu


protocol P2PRepository: WebGameCreateRepository {
    func getTurnOverStatus() -> Single<P2PTurnOver>
    func getAllGames() -> Single<[P2PGame]>
}

class P2PRepositoryImpl: P2PRepository {
    private var p2pApi: P2PApi!
    private var httpClient: HttpClient!
    
    init(_ p2pApi: P2PApi, httpClient: HttpClient) {
        self.p2pApi = p2pApi
        self.httpClient = httpClient
    }
    
    func getTurnOverStatus() -> Single<P2PTurnOver> {
        p2pApi.checkBonusLockStatus()
            .map { [weak self] (response) -> P2PTurnOver in
                guard let self = self,
                      let data = response.data
                else { return .None() }
                
                if !data.bonusLocked && !data.hasBonusTag {
                    return .None()
                }
                else if data.bonusLocked && data.hasBonusTag {
                    guard let currentBonus = data.currentBonus else { return .Calculating() }
                    return try self.convertToTurnOverReceipt(bean: currentBonus)
                }
                else {
                    return .Calculating()
                }
            }
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        p2pApi.getAllGames()
            .map { [weak self] (response) -> [P2PGame] in
                guard let self = self,
                      let data = response.data
                else { return [] }
                
                return data.map { (bean) -> P2PGame in
                    P2PGame.init(
                        gameId: bean.gameId,
                        gameName: bean.name,
                        isFavorite: false,
                        gameStatus: GameStatus.Companion.init().convert(
                            gameMaintenance: false,
                            status: bean.status
                        ),
                        thumbnail: P2PThumbnail.init(
                            host: self.httpClient.host.absoluteString,
                            thumbnailId: bean.imageId
                        )
                    )
                }
            }
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        p2pApi.getGameUrl(
            gameId: gameId,
            siteUrl: httpClient.host.absoluteString
        )
        .map { (response) -> URL? in
            guard let data = response.data else { return nil }
            return URL(string: data)
        }
        .catchException(transferLogic: {
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

