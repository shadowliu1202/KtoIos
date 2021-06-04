import Foundation
import RxSwift
import SharedBu
import Moya

class SlotApi: ApiService {
    let prefix = "slot/api"
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
   
    func getFavoriteSlots() -> Single<ResponseData<[SlotGameBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/favorite"))
        return httpClient.request(target).map(ResponseData<[SlotGameBean]>.self)
    }
    
    func addFavoriteCasino(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/add/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func removeFavoriteCasino(id: Int32) -> Completable {
        let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/remove/\(id)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func getHotGame() -> Single<ResponseData<SlotHotGamesBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/mobile/overview/hot"))
        return httpClient.request(target).map(ResponseData<SlotHotGamesBean>.self)
    }
    
    func getRecentGames() -> Single<ResponseData<[RecentGameBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/mobile/player-recent-games"))
        return httpClient.request(target).map(ResponseData<[RecentGameBean]>.self)
    }
    
    func slotKeywordSuggestion() -> Single<ResponseData<[String]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/keyword-suggestion"))
        return httpClient.request(target).map(ResponseData<[String]>.self)
    }
    
    func searchSlot(keyword: String) -> Single<ResponseData<[SlotGameBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/search-keyword")).parameters(["keyword": keyword])
        return httpClient.request(target).map(ResponseData<[SlotGameBean]>.self)
    }
    
    func search(sortBy: Int32, isJackpot: Bool, isNew: Bool, featureTags: Int32, themeTags: Int32, payLineWayTags: Int32) -> Single<ResponseData<[SlotGameBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/search"))
            .parameters(["SortBy": sortBy,
                         "isJackpot": "\(isJackpot)",
                         "isNew": "\(isNew)",
                         "featureTags": featureTags,
                         "themeTags": themeTags,
                         "payLineWayTags": payLineWayTags])
        return httpClient.request(target).map(ResponseData<[SlotGameBean]>.self)
    }
    
    func gameCount(sortBy: Int32, isJackpot: Bool, isNew: Bool, featureTags: Int32, themeTags: Int32, payLineWayTags: Int32) -> Single<ResponseData<Int>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/gamecount"))
            .parameters(["SortBy": sortBy,
                         "isJackpot": "\(isJackpot)",
                         "isNew": "\(isNew)",
                         "featureTags": featureTags,
                         "themeTags": themeTags,
                         "payLineWayTags": payLineWayTags])
        return httpClient.request(target).map(ResponseData<Int>.self)
    }
    
    func getSlotBetSummary(offset: Int32) -> Single<ResponseData<SlotBetSummaryBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/summary")).parameters(["offset": offset])
        return httpClient.request(target).map(ResponseData<SlotBetSummaryBean>.self)
    }
    
    func getNewAndJackpotGames() -> Single<ResponseData<SlotNewAndJackpotBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/mobile/overview/new"))
        return httpClient.request(target).map(ResponseData<SlotNewAndJackpotBean>.self)
    }
    
    func getSlotGameRecordByDate(date: String, offset: Int32) -> Single<ResponseData<[SlotDateGameRecordBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/gamegroup")).parameters(["date":date, "offset": offset])
        return httpClient.request(target).map(ResponseData<[SlotDateGameRecordBean]>.self)
    }
    
    func getSlotBetRecordByPage(beginDate: String, endDate: String, gameId: Int32, offset: Int, take: Int) -> Single<ResponseData<ResponseDataPage<SlotBetRecordBean>>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/list-by-paging")).parameters(["beginDate":beginDate, "endDate": endDate, "gameId": gameId, "offset": offset, "take": take])
        return httpClient.request(target).map(ResponseData<ResponseDataPage<SlotBetRecordBean>>.self)
    }
    
    func getUnsettleGameSummary(offset: Int32) -> Single<ResponseData<[SlotUnsettledSummaryBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/pending/group")).parameters(["offset": offset])
        return httpClient.request(target).map(ResponseData<[SlotUnsettledSummaryBean]>.self)
    }
    
    func getUnsettleGameRecords(date: String, offset: Int, take: Int) -> Single<ResponseData<ResponseDataPage<SlotUnsettledRecordBean>>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/pending/list-by-paging")).parameters(["date": date, "offset": offset, "take": take])
        return httpClient.request(target).map(ResponseData<ResponseDataPage<SlotUnsettledRecordBean>>.self)
    }
    
    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/url/\(gameId)")).parameters(["siteUrl": siteUrl])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
}
