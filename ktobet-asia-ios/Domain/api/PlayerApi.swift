import Foundation
import Moya
import RxSwift
import SwiftyJSON

class PlayerApi: ApiService {
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

  func getPlayerInfo() -> Single<ResponseData<PlayerBean>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/profile/player-info",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<PlayerBean>.self)
  }

  func getPlayerContact() -> Single<ResponseData<ContactInfoBean>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/profile/contact-info",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<ContactInfoBean>.self)
  }

  func sendOldAccountOtp(accountType: Int) -> Single<NonNullResponseData<Nothing>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/profile/verify-oldAccount",
      method: .post,
      task: .requestCompositeParameters(
        bodyParameters: [:],
        bodyEncoding: JSONEncoding.default,
        urlParameters: ["profileType": accountType]),
      header: httpClient.headers)
    return httpClient.request(target).map(NonNullResponseData<Nothing>.self)
  }

  func getCashBalance() -> Single<ResponseData<Double>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/cash/balance",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<Double>.self)
  }

  func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<ResponseData<[String: Double]>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/cash/transaction-summary",
      method: .get,
      task: .requestParameters(parameters: [
        "createdDateRange.begin": begin,
        "createdDateRange.end": end,
        "balanceLogFilterType": balanceLogFilterType
      ], encoding: URLEncoding.default),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<[String: Double]>.self)
  }

  func isRealNameEditable() -> Single<ResponseData<Bool>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/profile/realname-editable",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<Bool>.self)
  }

  func getPlayerLevel() -> Single<ResponseData<[LevelBean]>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/level",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<[LevelBean]>.self)
  }

  func getPlayerRealName() -> Single<ResponseData<String>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/profile/real-name",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<String>.self)
  }

  func getCultureCode() -> Single<NonNullResponseData<String>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/init/culture",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(NonNullResponseData<String>.self)
  }

  func getPlayerAffiliateStatus() -> Single<NonNullResponseData<Int32>> {
    let target = GetAPITarget(service: self.url("api/init/player-affiliate-status"))
    return httpClient.request(target).map(NonNullResponseData<Int32>.self)
  }

  func getAffiliateHashKey() -> Single<NonNullResponseData<String>> {
    let target = GetAPITarget(service: self.url("api/auth/affiliate-redirect"))
    return httpClient.request(target).map(NonNullResponseData<String>.self)
  }

  func checkProfileToken() -> Single<NonNullResponseData<Bool>> {
    let target = GetAPITarget(service: self.url("api/profile/check-token"))
    return httpClient.request(target).map(NonNullResponseData<Bool>.self)
  }

  func getPlayerProfile() -> Single<ResponseData<ProfileBean>> {
    let target = GetAPITarget(service: self.url("api/profile"))
    return httpClient.request(target).map(ResponseData<ProfileBean>.self)
  }

  func verifyPassword(_ request: RequestVerifyPassword) -> Single<ResponseData<Bool>> {
    let target = PostAPITarget(service: self.url("api/auth/verify-password"), parameters: request)
    return httpClient.request(target).map(ResponseData<Bool>.self)
  }

  func resetPassword(_ request: RequestResetPassword) -> Single<NonNullResponseData<Bool>> {
    let target = PostAPITarget(service: self.url("api/profile/reset-password"), parameters: request)
    return httpClient.request(target).map(NonNullResponseData<Bool>.self)
  }

  func setRealName(_ request: RequestSetRealName) -> Single<ResponseData<Nothing>> {
    let target = PostAPITarget(service: self.url("api/profile/realname"), parameters: request)
    return httpClient.request(target).map(ResponseData<Nothing>.self)
  }

  func verifyChangeIdentityOtp(_ request: RequestVerifyOtp) -> Single<NonNullResponseData<Nothing>> {
    let target = PostAPITarget(service: self.url("api/profile/verify-otp"), parameters: request)
    return httpClient.request(target).map(NonNullResponseData<Nothing>.self)
  }

  func resendOtp(_ type: Int) -> Single<ResponseData<Nothing>> {
    let target = PostAPITarget(service: self.url("api/profile/resend-otp/\(type)"))
    return httpClient.request(target).map(ResponseData<Nothing>.self)
  }

  func setBirthDay(_ request: RequestChangeBirthDay) -> Completable {
    let target = PostAPITarget(service: self.url("api/profile/birthday"), parameters: request)
    return httpClient.request(target).asCompletable()
  }

  func bindIdentity(request: RequestChangeIdentity) -> Single<NonNullResponseData<Nothing>> {
    let target = PostAPITarget(service: self.url("api/profile/bind"), parameters: request)
    return httpClient.request(target).map(NonNullResponseData<Nothing>.self)
  }

  // MARK: New

  func _getCashBalance() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/cash/balance",
          method: .get))
  }
}
