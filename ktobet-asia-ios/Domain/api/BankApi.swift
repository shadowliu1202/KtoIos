import Foundation
import Moya
import RxSwift
import sharedbu

class BankApi: ApiService {
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

    func getBanks() -> Single<ResponseData<[SimpleBank]>> {
        let target = APITarget(
            baseUrl: httpClient.host,
            path: "api/init/bank",
            method: .get,
            task: .requestPlain,
            header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[SimpleBank]>.self)
    }
}
