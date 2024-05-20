import Foundation
import RxSwift
import sharedbu

class CommonAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getBanks() -> Single<String> {
        httpClient
            .requestJsonString(
                NewAPITarget(
                    path: "api/init/bank",
                    method: .get))
    }
}
