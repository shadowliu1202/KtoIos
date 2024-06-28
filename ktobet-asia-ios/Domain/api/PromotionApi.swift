import Foundation
import Moya
import RxSwift
import sharedbu

class PromotionApi {
    let prefix = "api/bonus"

    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func searchPromotionHistory(request: PromotionHistoryRequest) -> Single<PromotionHistoryBean?> {
        httpClient.request(path: "\(prefix)/history", method: .post, task: .requestJSONEncodable(request))
    }

    func getBonusCoupons() -> Single<BonusBean?> {
        httpClient.request(path: "\(prefix)", method: .get)
    }

    func getLockedBonus() -> Single<LockBonusBean?> {
        httpClient.request(path: "\(prefix)/locked", method: .get)
    }

    func checkBonusTag() -> Single<BonusTagBean?> {
        httpClient.request(path: "\(prefix)/current", method: .get)
    }

    func getCurrentLockedBonus() -> Single<LockedBonusDataBean?> {
        httpClient.request(path: "\(prefix)/current-bonus", method: .get)
    }

    func getCouponTurnOverDetail(bonusId: String) -> Single<BonusHintBean?> {
        httpClient.request(path: "\(prefix)/trial/\(bonusId)", method: .get)
    }

    func useBonusCoupon(bonus: BonusRequest) -> Completable {
        httpClient.request(path: "\(prefix)", method: .post, task: .requestJSONEncodable(bonus)).asCompletable()
    }

    func getBonusContent(displayId: String, couponNumber: String) -> Single<PromotionContentBean?> {
        httpClient.request(path: "\(prefix)/content/\(displayId)/\(couponNumber)", method: .get)
    }

    func getBonusContentTemplate(displayId: String) -> Single<PromotionTemplateBean?> {
        httpClient.request(path: "\(prefix)/template/\(displayId)", method: .get)
    }

    func getCashBackSettings(displayId: String) -> Single<[CashBackSettingBean]> {
        httpClient.request(path: "\(prefix)/cashback/reference-percentage", method: .get, task: .urlParameters(["displayId": displayId]))
    }
}
