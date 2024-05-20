import Foundation

class P2PMyBetAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
  
    func getDetail(id: String) -> Single<String> {
        httpClient
            .requestJsonString(
                path: "/p2p/api/wager/mybet/detail",
                method: .get,
                task: .requestParameters(
                    parameters: [
                        "wagerId": id
                    ]))
    }
}
