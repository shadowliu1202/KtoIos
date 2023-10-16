import Foundation
import Moya
import RxSwift
import sharedbu

class ArcadeApi: ApiService, WebGameApi {
  let prefix = "arcade/api"
  private var urlPath: String!

  private func url(_ u: String) -> Self {
    self.urlPath = u
    return self
  }

  private var httpClient: HttpClient!

  var surfixPath: String {
    self.urlPath
  }

  var headers: [String: String]? {
    httpClient.headers
  }

  var baseUrl: URL {
    httpClient.host
  }

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func searchGames(sortBy: Int32, isRecommend: Bool, isNew: Bool) -> Single<ResponseData<[ArcadeGameDataBean]>> {
    let param: [String: Any] = ["sortBy": sortBy, "isRecommend": "\(isRecommend)", "isNew": "\(isNew)", "themeTags": 0]
    let target = GetAPITarget(service: self.url("\(prefix)/game/lobby/search")).parameters(param)
    return httpClient.request(target).map(ResponseData<[ArcadeGameDataBean]>.self)
  }

  func getBetSummary(offset: Int32) -> Single<ResponseData<ArcadeSummaryBean>> {
    let target = GetAPITarget(service: self.url("\(prefix)/wager/mybet/summary")).parameters(["offset": offset])
    return httpClient.request(target).map(ResponseData<ArcadeSummaryBean>.self)
  }

  func getGameRecordByDate(date: String, offset: Int32, skip: Int, take: Int) -> Single<ResponseData<ArcadeDateBetRecordBean>> {
    let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/gamegroup"))
      .parameters(["date": date, "offset": offset, "skip": skip, "take": take])
    return httpClient.request(target).map(ResponseData<ArcadeDateBetRecordBean>.self)
  }

  func getBetRecords(
    beginDate: String,
    endDate: String,
    gameId: Int32,
    skip: Int,
    take: Int) -> Single<ResponseData<ArcadeGameBetRecordDataBean>>
  {
    let target = GetAPITarget(service: self.url("\(prefix)/wager/mobile/mybet/list-by-paging"))
      .parameters(["beginDate": beginDate, "endDate": endDate, "gameId": gameId, "skip": skip, "take": take])
    return httpClient.request(target).map(ResponseData<ArcadeGameBetRecordDataBean>.self)
  }

  func getFavoriteArcade() -> Single<ResponseData<[ArcadeGameDataBean]>> {
    self.getFavoriteGameList()
  }

  func searchGames(keyword: String) -> Single<ResponseData<[ArcadeGameDataBean]>> {
    self.searchGameList(keyword: keyword)
  }

  // MARK: WebGameApi
  func addFavoriteGame(id: Int32) -> Completable {
    let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/add/\(id)"), parameters: .empty)
    return httpClient.request(target).asCompletable()
  }

  func removeFavoriteGame(id: Int32) -> Completable {
    let target = PutAPITarget(service: self.url("\(prefix)/game/favorite/remove/\(id)"), parameters: .empty)
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

  func getArcadeTagsWithCount() -> Single<String> {
    let target = GetAPITarget(service: self.url("\(prefix)/game/mobile/tag-with-gamecount"))
    return httpClient.requestJsonString(target)
  }
}
