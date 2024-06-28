import Foundation
import Moya
import RxSwift
import sharedbu

class ArcadeApi: WebGameApi {
    let prefix = "arcade/api"

    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func searchGames(sortBy: Int32, isRecommend: Bool, isNew: Bool) -> Single<[ArcadeGameDataBean]?> {
        httpClient.request(
            path: "\(prefix)/game/lobby/search",
            method: .get,
            task: .urlParameters(["sortBy": sortBy, "isRecommend": "\(isRecommend)", "isNew": "\(isNew)", "themeTags": 0])
        )
    }

    func getBetSummary(offset: Int32) -> Single<ArcadeSummaryBean?> {
        httpClient.request(path: "\(prefix)/wager/mybet/summary", method: .get, task: .urlParameters(["offset": offset]))
    }

    func getGameRecordByDate(date: String, offset: Int32, skip: Int, take: Int) -> Single<ArcadeDateBetRecordBean?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/gamegroup",
            method: .get,
            task: .urlParameters(["date": date, "offset": offset, "skip": skip, "take": take])
        )
    }

    func getBetRecords(beginDate: String, endDate: String, gameId: Int32, skip: Int, take: Int) -> Single<ArcadeGameBetRecordDataBean?> {
        httpClient.request(
            path: "\(prefix)/wager/mobile/mybet/list-by-paging",
            method: .get,
            task: .urlParameters(["beginDate": beginDate, "endDate": endDate, "gameId": gameId, "skip": skip, "take": take])
        )
    }

    func getFavoriteArcade() -> Single<[ArcadeGameDataBean]?> {
        httpClient.request(path: "\(prefix)/game/favorite", method: .get)
    }

    func searchGames(keyword: String) -> Single<[ArcadeGameDataBean]?> {
        httpClient.request(path: "\(prefix)/game/search-keyword", method: .get, task: .urlParameters(["keyword": keyword]))
    }

    // MARK: WebGameApi

    func addFavoriteGame(id: Int32) -> Completable {
        httpClient.request(path: "\(prefix)/game/favorite/add/\(id)", method: .put).asCompletable()
    }

    func removeFavoriteGame(id: Int32) -> Completable {
        httpClient.request(path: "\(prefix)/game/favorite/remove/\(id)", method: .get).asCompletable()
    }

    func getSuggestKeywords() -> Single<[String]?> {
        httpClient.request(path: "\(prefix)/game/keyword-suggestion", method: .get)
    }

    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<String?> {
        httpClient.request(path: "\(prefix)/game/url/\(gameId)", method: .get, task: .urlParameters(["siteUrl": siteUrl]))
    }

    func getArcadeTagsWithCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
        return httpClient.request(path: "\(prefix)/game/mobile/tag-with-gamecount", method: .get)
            .asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
    }
}
