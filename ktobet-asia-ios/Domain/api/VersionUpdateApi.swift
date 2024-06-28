import Foundation
import Moya
import RxSwift

class VersionUpdateApi {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getIOSVersion() -> Single<VersionData> {
        httpClient.request(path: "ios/api/get-ios-ipa-version", method: .get)
    }

    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
        httpClient.request(path: "api/init/ios-maintenance", method: .get)
    }
}
