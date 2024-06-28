import Foundation
import Moya
import RxSwift
import SwiftyJSON
import sharedbu

class PlayerApi {
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getPlayerInfo() -> Single<PlayerBean?> {
        httpClient.request(path: "api/profile/player-info", method: .get)
    }

    func getPlayerContact() -> Single<ContactInfoBean?> {
        httpClient.request(path: "api/profile/contact-info", method: .get)
    }

    func sendOldAccountOtp(accountType: Int) -> Completable {
        httpClient.request(
            path: "api/profile/verify-oldAccount",
            method: .post,
            task: .requestCompositeParameters(
                bodyParameters: [:],
                bodyEncoding: JSONEncoding.default,
                urlParameters: ["profileType": accountType]
            )
        )
        .asCompletable()
    }

    func getCashBalance() -> Single<Double?> {
        httpClient.request(path: "api/cash/balance", method: .get)
    }

    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<[String: Double]?> {
        httpClient.request(
            path: "api/cash/transaction-summary",
            method: .get,
            task: .urlParameters([
                "createdDateRange.begin": begin,
                "createdDateRange.end": end,
                "balanceLogFilterType": balanceLogFilterType,
            ])
        )
    }

    func isRealNameEditable() -> Single<Bool?> {
        httpClient.request(path: "api/profile/realname-editable", method: .get)
    }

    func getPlayerLevel() -> Single<[LevelBean]?> {
        return httpClient.request(path: "api/level", method: .get)
    }

    func getPlayerRealName() -> Single<String?> {
        return httpClient.request(path: "api/profile/real-name", method: .get)
    }

    func getCultureCode() -> Single<String> {
        httpClient.request(path: "api/init/culture", method: .get)
    }

    func getPlayerAffiliateStatus() -> Single<Int32> {
        httpClient.request(path: "api/init/player-affiliate-status", method: .get)
    }

    func getAffiliateHashKey() -> Single<String> {
        httpClient.request(path: "api/auth/affiliate-redirect", method: .get)
    }

    func checkProfileToken() -> Single<Bool> {
        httpClient.request(path: "api/profile/check-token", method: .get)
    }

    func getPlayerProfile() -> Single<ProfileBean?> {
        httpClient.request(path: "api/profile", method: .get)
    }

    func verifyPassword(_ request: RequestVerifyPassword) -> Completable {
        httpClient.request(path: "api/auth/verify-password", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    func resetPassword(_ request: RequestResetPassword) -> Completable {
        httpClient.request(path: "api/profile/reset-password", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    func setRealName(_ request: RequestSetRealName) -> Completable {
        httpClient.request(path: "api/profile/realname", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    func verifyChangeIdentityOtp(_ request: RequestVerifyOtp) -> Completable {
        httpClient.request(path: "api/profile/verify-otp", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    func resendOtp(_ type: Int) -> Completable {
        httpClient.request(path: "api/profile/resend-otp/\(type)", method: .post, task: .requestPlain)
            .asCompletable()
    }

    func setBirthDay(_ request: RequestChangeBirthDay) -> Completable {
        httpClient.request(path: "api/profile/birthday", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    func bindIdentity(request: RequestChangeIdentity) -> Completable {
        httpClient.request(path: "api/profile/bind", method: .post, task: .requestJSONEncodable(request))
            .asCompletable()
    }

    // MARK: New

    func _getCashBalance() -> SingleWrapper<ResponseItem<NSString>> {
        httpClient.request(path: "api/cash/balance", method: .get)
            .asReaktiveResponseItem { (number: NSNumber) -> NSString in
                NSString(string: number.stringValue)
            }
    }
}
