import Foundation
import RxSwift
import SharedBu
import Moya

class CasinoApi: ApiService, WebGameApi {
    let prefix = "casino/api"
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
    
    func getCasinoGames() -> Single<ResponseDataList<TopCasinoResponse>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/top"))
        return httpClient.request(target).map(ResponseDataList<TopCasinoResponse>.self)
    }
    
    func getCasinoTags(culture: String) -> Single<ResponseDataMap<[TagBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/tag")).parameters(["culture" : culture])
        return httpClient.request(target).map(ResponseDataMap<[TagBean]>.self)
    }
    
    func getCasinoBetSummary(offset: Int32) -> Single<ResponseData<BetSummaryData>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/summary")).parameters(["offset": offset])
        return httpClient.request(target).map(ResponseData<BetSummaryData>.self)
    }
    
    func getGameGroup(date: String, offset: Int32) -> Single<ResponseData<[CasinoGroupData]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/gamegroup")).parameters(["date":date, "offset": offset])
        return httpClient.request(target).map(ResponseData<[CasinoGroupData]>.self)
    }
    
    func getBetRecordsByPage(lobbyId: Int, beginDate: String, endDate: String, offset: Int, take: Int) -> Single<ResponseData<CasinoBetData>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/list-by-paging"))
            .parameters(["lobbyId":lobbyId,
                         "beginDate": beginDate,
                         "endDate": endDate,
                         "offset":offset,
                         "take": take])
        return httpClient.request(target).map(ResponseData<CasinoBetData>.self)
    }
    
    func getFavoriteCasinos() -> Single<ResponseData<[CasinoData]>> {
        return self.getFavoriteGameList()
    }
    
    func searchCasino(keyword: String) -> Single<ResponseData<[CasinoData]>> {
        return self.searchGameList(keyword: keyword)
    }
    
    func search(sortBy: Int, map: [String: String]) -> Single<ResponseData<[CasinoData]>> {
        var param: [String: Any] = ["SortBy": sortBy]
        map.forEach { (k,v) in param[k] = v }
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/search")).parameters(param)
        return httpClient.request(target).map(ResponseData<[CasinoData]>.self)
    }
    
    func getWagerDetail(wagerId: String) -> Single<ResponseData<CasinoWagerDetail>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/detail")).parameters(["wagerId": wagerId])
        return httpClient.request(target).map(ResponseData<CasinoWagerDetail>.self)
    }
    
    func getUnsettledSummary(offset: Int32) -> Single<ResponseData<[UnsettledSummaryBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/pending/group")).parameters(["offset": offset])
        return httpClient.request(target).map(ResponseData<[UnsettledSummaryBean]>.self)
    }
    
    func getUnsettledRecords(date: String) -> Single<ResponseData<[UnsettledRecordBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/pending/list")).parameters(["date": date])
        return httpClient.request(target).map(ResponseData<[UnsettledRecordBean]>.self)
    }
    
    // MARK: WebGameApi
    func addFavoriteGame(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/add/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func removeFavoriteGame(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/remove/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func getFavoriteGameList<T>() -> Single<ResponseData<[T]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/favorite"))
        return httpClient.request(target).map(ResponseData<[T]>.self)
    }
    
    func getSuggestKeywords() -> Single<ResponseData<[String]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/keyword-suggestion"))
        return httpClient.request(target).map(ResponseData<[String]>.self)
    }
    
    func searchGameList<T>(keyword: String) -> Single<ResponseData<[T]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/search-keyword")).parameters(["keyword": keyword])
        return httpClient.request(target).map(ResponseData<[T]>.self)
    }
    
    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/url/\(gameId)")).parameters(["siteUrl": siteUrl])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
}
