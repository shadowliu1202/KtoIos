import Foundation
import Moya
import RxSwift
import sharedbu

class NotificationApi {
    private var urlPath: String!
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getActivityNotification() -> Single<ActivityMessagePageBean?> {
        httpClient.request(path: "api/notify/my-activity", method: .get)
    }

    func getPlayerAllNotification(page: Int, keyword: String) -> Single<InternalMessagePageBean?> {
        httpClient.request(path: "api/notify/get-player-all-message", method: .get, task: .urlParameters(["page": page, "keyword": keyword]))
    }

    func deleteNotification(messageId: String) -> Completable {
        httpClient.request(path: "api/notify/personal/\(messageId)", method: .delete).asCompletable()
    }
}
