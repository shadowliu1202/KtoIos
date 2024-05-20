import Foundation
import Moya
import RxSwift
import sharedbu

class PromotionApi: ApiService {
    let prefix = "api/bonus"
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

    func searchPromotionHistory(request: PromotionHistoryRequest) -> Single<ResponseData<PromotionHistoryBean>> {
        let target = PostAPITarget(service: self.url("\(prefix)/history"), parameters: request)
        return httpClient.request(target).map(ResponseData<PromotionHistoryBean>.self)
    }

    func getBonusCoupons() -> Single<ResponseData<BonusBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)"))
        return httpClient.request(target).map(ResponseData<BonusBean>.self)
    }

    func getLockedBonus() -> Single<ResponseData<LockBonusBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/locked"))
        return httpClient.request(target).map(ResponseData<LockBonusBean>.self)
    }

    func checkBonusTag() -> Single<ResponseData<BonusTagBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/current"))
        return httpClient.request(target).map(ResponseData<BonusTagBean>.self)
    }

    func getCurrentLockedBonus() -> Single<ResponseData<LockedBonusDataBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/current-bonus"))
        return httpClient.request(target).map(ResponseData<LockedBonusDataBean>.self)
    }

    func getCouponTurnOverDetail(bonusId: String) -> Single<ResponseData<BonusHintBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/trial/\(bonusId)"))
        return httpClient.request(target).map(ResponseData<BonusHintBean>.self)
    }

    func useBonusCoupon(bonus: BonusRequest) -> Single<ResponseData<Nothing>> {
        let target = PostAPITarget(service: self.url("\(prefix)"), parameters: bonus)
        return httpClient.request(target).map(ResponseData<Nothing>.self)
    }

    func getBonusContent(displayId: String, couponNumber: String) -> Single<ResponseData<PromotionContentBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/content/\(displayId)/\(couponNumber)"))
        return httpClient.request(target).map(ResponseData<PromotionContentBean>.self)
    }

    func getBonusContentTemplate(displayId: String) -> Single<ResponseData<PromotionTemplateBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/template/\(displayId)"))
        return httpClient.request(target).map(ResponseData<PromotionTemplateBean>.self)
    }

    func getCashBackSettings(displayId: String) -> Single<ResponseDataList<CashBackSettingBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/cashback/reference-percentage"))
            .parameters(["displayId": displayId])
        return httpClient.request(target).map(ResponseDataList<CashBackSettingBean>.self)
    }
}
