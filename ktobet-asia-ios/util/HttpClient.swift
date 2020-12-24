//
//  API.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/19.
//

import Foundation
import Moya
import RxSwift
import Alamofire
import SwiftyJSON

private func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}

enum ErrorType : Int {
    case PlayerIsExist = 10002
    case PlayerIsNotExist = 10001
    case PlayerLoginFail = 10003
    case PlayerEditFail = 10004
    case PlayerRegisterFail = 10005
    case PlayerAddTempPlayerFail = 10006
    case PlayerGetTempPlayerFail = 10007
    case PlayerResentOtpOverTenTimes = 10008
    case PlayerAddInfoFail = 10009
    case PlayerChangePasswordFail = 10010
    case PlayerPasswordFail = 10011
    case PlayerAddCaptchaFail = 10012
    case PlayerCaptchaCheckError = 10013
    case PlayerDuplicatedLogin = 10014
    case PlayerAddForgetPasswordTempDataFail = 10015
    case PlayerGetForgetPasswordTempDataFail = 10016
    case PlayerPasswordRepeat = 10017
    case PlayerCaptchaNotFound = 10019
    case PlayerIsLocked = 10020
    case PlayerIsSuspend = 10021
    case PlayerIsInactive = 10022
    case PlayerApplyResetPasswordRepeat = 10023
    case PlayerResentOtpLessResendTime = 10024
    case PlayerAddWithdrawalCacheFail = 10025
    case PlayerOverOtpRetryLimit = 10026
    case PlayerIpOverOtpDailyLimit = 10027
    case PlayerIdOverOtpLimit = 10028
    case PlayerForgetPasswordTempDataExist = 10029
    case PlayerLoginIdIsExist = 10030
    case PlayerIsNotLogged = 10031
    case PlayerAffiliateApplyStatusIsApplying = 10032
    case PlayerAffiliateApplyStatusIsAppliedButInActive = 10033
    case PlayerAffiliateApplyStatusIsAppliedButSuspend = 10034
    case PlayerDepositCountOverLimit = 10101
    case PlayerPaymentTokenInactive = 10102
    case PlayerPaymentTokenNotInPlayerPaymentGroup = 10103
    case PlayerWithdrawalDefective = 10104
    case PlayerOtpCheckError = 10200
    case PlayerOtpInsertRedisError = 10201
    case PlayerSendOtpTargetAddressError = 10202
    case PlayerSendOtpTypeError = 10203
    case PlayerUrlOtpInsertRedisError = 10204
    case PlayerOtpCheckErrorByChangePassword = 10205
    case PlayerSendOtpFail = 10206
    case PlayerOtpMailInactive = 10207
    case PlayerOtpSmsInactive = 10208
    case PlayerReSendOtpError = 10209
    case PlayerCommentIsNotExist = 10300
    case PlayerChatTokenError = 10400
    case PlayerChatNotAllow = 10401
    case PlayerProfileUpdateError = 10500
    case PlayerProfileAddError = 10501
    case PlayerProfileBindError = 10502
    case PlayerProfileAlreadyExist = 10503
    case PlayerProfileInvalidInput = 10504
    case PlayerProfileRealNameChangeForbidden = 10505
    case BonusReachTheApplicantLimitation = 10701
    case BonusBalanceLowerMinimumLimit = 10702
    case BonusCouponIsLocked = 10703
    case BonusCouponDepositAmountOrTimesNotEnough = 10704
    case BonusCouponIsUsing = 10705
    case BonusCouponIsNotExist = 10706
    case BonusPlayerTurnoverIsNotExists = 10707
    case BonusElkNoResult = 10708
    case BonusCouponIsUsed = 10709
    case PlayerRegisterError = 10801
    case PlayerForgetPasswordError = 10802
    case DBPlayerNotExist = 50000
    case DBPlayerAlreadyExist = 50001
    case DBPlayerUpdateError = 50002
    case DBPlayerWithdrawalRequestInsufficientBalance = 50101
    case ApiUnknownException
}

class HttpClient {
    
    let provider : MoyaProvider<MultiTarget>!
    var session : Session { return AF}
    var host : String { return "https://qat1-mobile.affclub.xyz/"}
//    var host : String { return "https://qat1.pivotsite.com/"}
    var baseUrl : URL { return URL(string: self.host)!}
    var headers : [String : String] {
        var header : [String : String] = [:]
        //headers.add(name: "Accept-Charset", value: "UTF-8")
        header["Accept"] = "application/json"
        header["User-Agent"] = "kto-ios/13.0"
        header["Cookie"] = {
            var token : [String] = []
            for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: baseUrl) ?? []  {
                token.append(cookie.name + "=" + cookie.value)
            }
            return token.joined(separator: ";")
        }()
        return header
    }
    
    init() {
        let formatter : NetworkLoggerPlugin.Configuration.Formatter = .init(responseData: JSONResponseDataFormatter)
        let logOptions : NetworkLoggerPlugin.Configuration.LogOptions = .verbose
        let configuration : NetworkLoggerPlugin.Configuration = .init(formatter: formatter, logOptions: logOptions)
        provider = MoyaProvider<MultiTarget>(plugins: [NetworkLoggerPlugin(configuration: configuration)]) // debug
    }

    func request(_ target: APITarget) -> Single<Response> {
        return provider
            .rx
            .request(MultiTarget(target))
            .filterSuccessfulStatusCodes()
            .flatMap({ (response) -> Single<Response> in
                if let json = try? JSON.init(data: response.data),
                   let statusCode = json["statusCode"].string,
                   let errorMsg = json["errorMsg"].string,
                   statusCode.count > 0 && errorMsg.count > 0{
                    let domain = self.baseUrl.path
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["errorMsg" : errorMsg])
                    return Single.error(error)
                }
                return Single.just(response)
            })
    }
    
    func getCookies()->[HTTPCookie]{
        return session.sessionConfiguration.httpCookieStorage?.cookies(for: self.baseUrl) ?? []
    }
    
    func getToken()->String{
        var token : [String] = []
        for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: self.baseUrl) ?? []  {
            token.append(cookie.name + "=" + cookie.value)
        }
        return token.joined(separator: ";")
    }
    
    func clearCookie()->Completable{
        return Completable.create { (completable) -> Disposable in
            let storage = self.session.sessionConfiguration.httpCookieStorage
            for cookie in self.getCookies(){
                storage?.deleteCookie(cookie)
            }
            completable(.completed)
            return Disposables.create {}
        }
    }
}
