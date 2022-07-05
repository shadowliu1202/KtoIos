import Foundation
import RxSwift
import SharedBu
import Moya


class P2PApi: ApiService {
    let prefix = "p2p/api"
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
    
    var baseUrl: URL {
        return httpClient.host
    }
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func checkBonusLockStatus() -> Single<ResponseData<P2PTurnOverBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/player/bonus-locked"))
        return httpClient.request(target).map(ResponseData<P2PTurnOverBean>.self)
    }
    
    func getAllGames() -> Single<ResponseData<[P2PGameBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/overview"))
        return httpClient.request(target).map(ResponseData<[P2PGameBean]>.self)
    }
    
    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/game/url/\(gameId)")).parameters(["siteUrl": siteUrl])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    func getBetSummary(offset: Int32) -> Single<ResponseData<P2PBetSummaryBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/summary")).parameters(["offset": offset])
        return httpClient.request(target).map(ResponseData<P2PBetSummaryBean>.self)
    }
    
    func getGameRecordByDate(date: String, offset: Int32) -> Single<ResponseData<[P2PDateBetRecordBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/gamegroup")).parameters(["date": date, "offset": offset])
        return httpClient.request(target).map(ResponseData<[P2PDateBetRecordBean]>.self)
    }
    
    func getBetRecords(beginDate: String, endDate: String, gameId: Int32) -> Single<ResponseData<[P2PGameBetRecordBean]>> {
        let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/list")).parameters(["beginDate": beginDate, "endDate": endDate, "gameId": gameId])
        return httpClient.request(target).map(ResponseData<[P2PGameBetRecordBean]>.self)
    }
    
}
