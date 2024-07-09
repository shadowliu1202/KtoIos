import Foundation
import Moya
import RxSwift
import sharedbu

class CasinoApi: WebGameApi {
    let prefix = "casino/api"

    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getCasinoGames() -> Single<[TopCasinoResponse]> {
        httpClient.request(path: "\(prefix)/game/lobby/top", method: .get)
    }

    func getCasinoTags(culture: String) -> Single<[String: [TagBean]]> {
        httpClient.request(path: "\(prefix)/game/tag", method: .get, task: .urlParameters(["culture": culture]))
    }

    func getCasinoBetSummary(offset: Int32) -> Single<BetSummaryData?> {
        httpClient.request(path: "\(prefix)/wager/mybet/summary", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getGameGroup(date: String, offset: Int32) -> Single<[CasinoGroupData]?> {
        httpClient.request(path: "\(prefix)/wager/mybet/gamegroup", method: .get, task: .urlParameters(["date": date, "offset": offset]))
    }

    func getBetRecordsByPage(lobbyId: Int, beginDate: String, endDate: String, offset: Int, take: Int) -> Single<CasinoBetData?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/list-by-paging",
            method: .get,
            task: .urlParameters([
                "lobbyId": lobbyId,
                "beginDate": beginDate,
                "endDate": endDate,
                "offset": offset,
                "take": take,
            ])
        )
    }

    func getFavoriteCasinos() -> Single<[CasinoData]?> {
        httpClient.request(path: "\(prefix)/game/favorite", method: .get)
    }

    func searchCasino(keyword: String) -> Single<[CasinoData]?> {
        httpClient.request(path: "\(prefix)/game/search-keyword", method: .get, task: .urlParameters(["keyword": keyword]))
    }

    func search(sortBy: Int, map: [String: String]) -> Single<[CasinoData]?> {
        var param: [String: Any] = ["SortBy": sortBy]
        map.forEach { k, v in param[k] = v }
        return httpClient.request(path: "\(prefix)/game/lobby/search", method: .get, task: .urlParameters(param))
    }

    func getUnsettledSummary(offset: Int32) -> Single<[UnsettledSummaryBean]?> {
        httpClient.request(path: "\(prefix)/wager/mybet/pending/group", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getUnsettledRecords(date: String) -> Single<[UnsettledRecordBean]?> {
        httpClient.request(path: "\(prefix)/wager/mybet/pending/list", method: .get, task: .urlParameters(["date": date]))
    }

    // MARK: WebGameApi

    func addFavoriteGame(id: Int32) -> Completable {
        httpClient.request(path: "\(prefix)/game/favorite/add/\(id)", method: .put).asCompletable()
    }

    func removeFavoriteGame(id: Int32) -> Completable {
        httpClient.request(path: "\(prefix)/game/favorite/remove/\(id)", method: .put).asCompletable()
    }

    func getSuggestKeywords() -> Single<[String]?> {
        httpClient.request(path: "\(prefix)/game/keyword-suggestion", method: .get)
    }

    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<String?> {
        httpClient.request(path: "\(prefix)/game/url/\(gameId)", method: .get, task: .urlParameters(["siteUrl": siteUrl]))
    }

    func getCasinoTagsWithCount() -> Single<String> {
        httpClient.request(path: "\(prefix)/game/mobile/tag-with-gamecount", method: .get)
    }
}
