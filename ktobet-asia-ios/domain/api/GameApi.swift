import Foundation
import Moya
import RxSwift
import SwiftyJSON

class GameApi {
  private var httpClient: HttpClient!

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getGameUrl() -> Single<URL> {
    let para = ["siteUrl": httpClient.host.absoluteString]
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "casino/api/game/url/55",
      method: .get,
      task: .requestParameters(parameters: para, encoding: URLEncoding.default),
      header: httpClient.headers)
    return httpClient.request(target)
      .map(ResponseData<String>.self)
      .map({ response -> URL in
        let path = response.data
        return URL(string: path!)!
      })
  }
}
