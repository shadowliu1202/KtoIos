import Foundation
import Moya
import RxSwift
import sharedbu

class NumberGameApi: WebGameApi {
    let prefix = "numbergame/api"
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getMyBetSummary(offset: Int = 8) -> Single<RecordSummaryResponse?> {
        httpClient.request(path: "\(prefix)/wager/mybet/summary", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getMyBetGameGroupByDate(date: String, offset: Int = 8, myBetType: Int32, skip: Int = 0, take: Int = 100) -> Single<GameGroupBetSummaryResponse?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/gamegroup",
            method: .get,
            task: .urlParameters(["date": date, "offset": offset, "myBetType": myBetType, "skip": skip, "take": take])
        )
    }

    func getMyGameBetInDuration(begindate: String, endDate: String, gameId: Int32, myBetType: Int32) -> Single<[BetSummaryDataResponse]?> {
        httpClient.request(
            path: "\(prefix)/wager/mybet/list",
            method: .get,
            task: .urlParameters(["begindate": begindate, "endDate": endDate, "gameId": gameId, "myBetType": myBetType])
        )
    }

    func getMyGameBetInDuration(begindate: String, endDate: String, gameId: Int32, myBetType: Int32, skip: Int = 0, take: Int = 100) -> Single<BetsSummaryResponse?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/list-by-paging",
            method: .get,
            task: .urlParameters(["begindate": begindate, "endDate": endDate, "gameId": gameId, "myBetType": myBetType, "skip": skip, "take": take])
        )
    }

    func getMyBetDetail(wagerId: String) -> Single<NumberGameBetDetailBean> {
        httpClient.request(path: "\(prefix)/wager/mobile/mybet/detail", method: .get, task: .urlParameters(["wagerId": wagerId]))
    }

    func getFavorite() -> Single<[NumberGameEntity]?> {
        httpClient.request(path: "\(prefix)/game/favorite", method: .get)
    }

    func searchKeyword(keyword: String) -> Single<[NumberGameEntity]?> {
        httpClient.request(path: "\(prefix)/game/search-keyword", method: .get, task: .urlParameters(["keyword": keyword]))
    }

    func getTags() -> Single<[String: [TagBean]]> {
        httpClient.request(path: "\(prefix)/game/tag", method: .get)
    }

    func searchGames(sortBy: Int32, isRecommend: Bool = false, isNew: Bool = false, map: [String: String]) -> Single<[NumberGameEntity]?> {
        var param: [String: Any] = ["SortBy": sortBy, "isRecommend": "\(isRecommend)", "isNew": "\(isNew)"]
        map.forEach { k, v in param[k] = v }
        return httpClient.request(path: "\(prefix)/game/lobby/search", method: .get, task: .urlParameters(param))
    }

    func getHotGame() -> Single<NumberGameHotBean?> {
        httpClient.request(path: "\(prefix)/game/mobile/overview/hot", method: .get)
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

    func getNumberGameTagsWithCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
        httpClient.request(path: "\(prefix)/game/mobile/tag-with-gamecount", method: .get)
            .asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
    }
}
