import Foundation
import Moya
import RxSwift
import sharedbu

class SlotApi: WebGameApi {
    let prefix = "slot/api"

    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getFavoriteSlots() -> Single<[SlotGameBean]?> {
        httpClient.request(path: "\(prefix)/game/favorite", method: .get)
    }

    func getHotGame() -> Single<SlotHotGamesBean?> {
        httpClient.request(path: "\(prefix)/game/mobile/overview/hot", method: .get)
    }

    func getRecentGames() -> Single<[RecentGameBean]?> {
        httpClient.request(path: "\(prefix)/game/mobile/player-recent-games", method: .get)
    }

    func searchSlot(keyword: String) -> Single<[SlotGameBean]?> {
        httpClient.request(
            path: "\(prefix)/game/search-keyword",
            method: .get,
            task: .urlParameters(["keyword": keyword])
        )
    }

    func search(
        sortBy: Int32,
        isJackpot: Bool,
        isNew: Bool,
        featureTags: Int32,
        themeTags: Int32,
        payLineWayTags: Int32
    ) -> Single<[SlotGameBean]?> {
        httpClient.request(path: "\(prefix)/game/lobby/search", method: .get,
                           task: .urlParameters([
                               "SortBy": sortBy,
                               "isJackpot": "\(isJackpot)",
                               "isNew": "\(isNew)",
                               "featureTags": featureTags,
                               "themeTags": themeTags,
                               "payLineWayTags": payLineWayTags,
                           ]))
    }

    func gameCount(
        sortBy: Int32,
        isJackpot: Bool,
        isNew: Bool,
        featureTags: Int32,
        themeTags: Int32,
        payLineWayTags: Int32
    ) -> Single<Int?> {
        httpClient.request(
            path: "\(prefix)/game/lobby/gamecount",
            method: .get,
            task: .urlParameters([
                "SortBy": sortBy,
                "isJackpot": "\(isJackpot)",
                "isNew": "\(isNew)",
                "featureTags": featureTags,
                "themeTags": themeTags,
                "payLineWayTags": payLineWayTags,
            ])
        )
    }

    func getSlotBetSummary(offset: Int32) -> Single<SlotBetSummaryBean?> {
        httpClient.request(path: "\(prefix)/wager/mybet/summary", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getNewAndJackpotGames() -> Single<SlotNewAndJackpotBean?> {
        httpClient.request(path: "\(prefix)/game/mobile/overview/new", method: .get)
    }

    func getSlotGameRecordByDate(date: String, offset: Int32) -> Single<[SlotDateGameRecordBean]?> {
        httpClient.request(path: "\(prefix)/wager/mobile/mybet/gamegroup", method: .get, task: .urlParameters(["date": date, "offset": offset]))
    }

    func getSlotBetRecordByPage(beginDate: String, endDate: String, gameId: Int32, offset: Int, take: Int) -> Single<ResponseDataPage<SlotBetRecordBean>?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/list-by-paging",
            method: .get,
            task: .urlParameters(
                [
                    "beginDate": beginDate,
                    "endDate": endDate,
                    "gameId": gameId,
                    "offset": offset,
                    "take": take,
                ]
            )
        )
    }

    func getUnsettleGameSummary(offset: Int32) -> Single<[SlotUnsettledSummaryBean]?> {
        httpClient.request(path: "\(prefix)/wager/mybet/pending/group", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getUnsettleGameRecords(date: String, offset: Int, take: Int) -> Single<ResponseDataPage<SlotUnsettledRecordBean>?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/pending/list-by-paging",
            method: .get,
            task: .urlParameters(["date": date, "offset": offset, "take": take])
        )
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
        httpClient.request(
            path: "\(prefix)/game/url/\(gameId)",
            method: .get,
            task: .urlParameters(["siteUrl": siteUrl])
        )
    }
}
