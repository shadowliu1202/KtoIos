import Foundation
import RxSwift
import Moya

class VersionUpdateApi: ApiService {
    
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
    
    func getIOSVersion() -> Single<NonNullResponseData<VersionData>> {
        let target = GetAPITarget(service: self.url("ios/api/get-ios-ipa-version"))
        return httpClient.request(target).map(NonNullResponseData<VersionData>.self)
    }
    
    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
        let target = GetAPITarget(service: self.url("api/download-ios-maintenance"))
        return httpClient.request(target).map(SuperSignMaintenanceBean.self)
    }
}

