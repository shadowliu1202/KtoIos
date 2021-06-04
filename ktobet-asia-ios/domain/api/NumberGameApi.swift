import Foundation
import RxSwift
import SharedBu
import Moya


class NumberGameApi: ApiService {
    let prefix = "numbergame/api"
    private var urlPath: String!
    
    private func url(_ u: String) -> Self {
        self.urlPath = u
        return self
    }
    private var httpClient : HttpClient!
    
    var surfixPath: String {
        return self.urlPath
    }
    
    var headers: [String : String]? {
        return httpClient.headers
    }
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getMyBetSummary(offset: Int = 8) -> Single<ResponseData<RecordSummaryResponse>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/summary"))
        return httpClient.request(target).map(ResponseData<RecordSummaryResponse>.self)
    }
    
    func getMyBetGameGroupByDate(date: String, offset: Int = 8, myBetType: Int32, skip: Int = 0, take: Int = 100) -> Single<ResponseData<GameGroupBetSummaryResponse>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/gamegroup")).parameters(["date": date,
                                                                                                           "offset": offset,
                                                                                                           "myBetType": myBetType,
                                                                                                           "skip": skip,
                                                                                                           "take": take])
        return httpClient.request(target).map(ResponseData<GameGroupBetSummaryResponse>.self)
    }
    
    func getMyGameBetInDuration(begindate: String, endDate: String, gameId: Int32, myBetType: Int32) -> Single<ResponseData<[BetSummaryDataResponse]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/list")).parameters(["begindate": begindate,
                                                                                               "endDate": endDate,
                                                                                               "gameId": gameId,
                                                                                               "myBetType": myBetType])
        return httpClient.request(target).map(ResponseData<[BetSummaryDataResponse]>.self)
    }
    
    func getMyGameBetInDuration(begindate: String, endDate: String, gameId: Int32, myBetType: Int32, skip: Int = 0, take: Int = 100) -> Single<ResponseData<BetsSummaryResponse>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/list-by-paging")).parameters(["begindate": begindate,
                                                                                                           "endDate": endDate,
                                                                                                           "gameId": gameId,
                                                                                                           "myBetType": myBetType,
                                                                                                           "skip": skip,
                                                                                                           "take": take])
        return httpClient.request(target).map(ResponseData<BetsSummaryResponse>.self)
    }
    
    func getMyBetDetail(wagerId: String) -> Single<NonNullResponseData<NumberGameBetDetailBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/detail")).parameters(["wagerId": wagerId])
        return httpClient.request(target).map(NonNullResponseData<NumberGameBetDetailBean>.self)
    }
    
    func addFavorite(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/add/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func removeFavorite(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/remove/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func getFavorite() -> Single<ResponseData<[NumberGameEntity]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/favorite"))
        return httpClient.request(target).map(ResponseData<[NumberGameEntity]>.self)
    }
    
    func keywordSuggestions() -> Single<ResponseData<[String]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/keyword-suggestion"))
        return httpClient.request(target).map(ResponseData<[String]>.self)
    }
    
    func searchKeyword(keyword: String) -> Single<ResponseData<[NumberGameEntity]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/search-keyword")).parameters(["keyword": keyword])
        return httpClient.request(target).map(ResponseData<[NumberGameEntity]>.self)
    }
    
    func getTags() -> Single<ResponseDataMap<[TagBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/tag"))
        return httpClient.request(target).map(ResponseDataMap<[TagBean]>.self)
    }
    
    func searchGames(sortBy: Int32, isRecommend: Bool = false, isNew: Bool = false, map: [String: String]) -> Single<ResponseData<[NumberGameEntity]>> {
        var param: [String: Any] = ["SortBy": sortBy, "isRecommend": "\(isRecommend)", "isNew": "\(isNew)"]
        map.forEach { (k,v) in param[k] = v }
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/search")).parameters(param)
        return httpClient.request(target).map(ResponseData<[NumberGameEntity]>.self)
    }
        func getGameUrl(gameId: Int32, siteUrl: String) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/url/\(gameId)")).parameters(["siteUrl": siteUrl])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getHotGame() -> Single<ResponseData<NumberGameHotBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/mobile/overview/hot"))
        return httpClient.request(target).map(ResponseData<NumberGameHotBean>.self)
    }
}

