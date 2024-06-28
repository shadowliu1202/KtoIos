import Foundation
import Moya
import RxSwift
import sharedbu

class P2PApi {
    let prefix = "p2p/api"
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func checkBonusLockStatus() -> Single<P2PTurnOverBean?> {
        httpClient.request(path: "\(prefix)/player/bonus-locked", method: .get)
    }

    func getAllGames() -> Single<[P2PGameBean]?> {
        httpClient.request(path: "\(prefix)/game/lobby/overview", method: .get)
    }

    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<String?> {
        httpClient.request(path: "\(prefix)/game/url/\(gameId)", method: .get, task: .urlParameters(["siteUrl": siteUrl]))
    }

    func getBetSummary(offset: Int32) -> Single<P2PBetSummaryBean?> {
        httpClient.request(path: "\(prefix)/wager/mybet/summary", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getGameRecordByDate(date: String, offset: Int32) -> Single<[P2PDateBetRecordBean]?> {
        httpClient.request(path: "\(prefix)/wager/mobile/mybet/gamegroup", method: .get, task: .urlParameters(["date": date, "offset": offset]))
    }

    func getBetRecords(beginDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecordBean]?> {
        httpClient.request(path: "\(prefix)/wager/mybet/list", method: .get, task: .urlParameters(["beginDate": beginDate, "endDate": endDate, "gameId": gameId]))
    }
}
