import Foundation
import Moya
import RxSwift
import sharedbu

class NotificationApi: ApiService {
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

    func getActivityNotification() -> Single<ResponseData<ActivityMessagePageBean>> {
        let target = GetAPITarget(service: self.url("api/notify/my-activity"))
        return httpClient.request(target).map(ResponseData<ActivityMessagePageBean>.self)
    }

    func getPlayerAllNotification(page: Int, keyword: String) -> Single<ResponseData<InternalMessagePageBean>> {
        let target = GetAPITarget(service: self.url("api/notify/get-player-all-message"))
            .parameters(["page": page, "keyword": keyword])
        return httpClient.request(target).map(ResponseData<InternalMessagePageBean>.self)
    }

    func deleteNotification(messageId: String) -> Completable {
        let target = DeleteAPITarget(service: self.url("api/notify/personal/\(messageId)"))
        return httpClient.request(target).asCompletable()
    }
}
