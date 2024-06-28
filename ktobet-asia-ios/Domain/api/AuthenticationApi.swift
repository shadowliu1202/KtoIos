import Foundation
import Moya
import RxSwift
import sharedbu

class AuthenticationApi {
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    // MARK: 註冊

    func register(_ registerRequest: IRegisterRequest) -> Completable {
        httpClient.request(path: "api/register", method: .post, task: .requestJSONEncodable(registerRequest)).asCompletable()
    }

    func verifyOtp(_ params: IVerifyOtpRequest) -> Completable {
        httpClient.request(path: "api/register/otp-verify", method: .post, task: .requestJSONEncodable(params)).asCompletable()
    }

    func resendRegisterOtp() -> Completable {
        httpClient.request(path: "api/register/resend-otp", method: .post).asCompletable()
    }

    func checkAccount(_ account: String) -> Single<Bool> {
        httpClient.request(
            path: "api/register/check-account-status",
            method: .get,
            task: .requestParameters(parameters: ["accountName": account], encoding: URLEncoding.default)
        )
    }

    // MARK: 登入

    func login(_ account: String, _ password: String, _ captcha: Captcha) -> Single<ILoginData> {
        httpClient.request(
            path: "api/auth/login",
            method: .post,
            task: .requestJSONEncodable(LoginRequest(account: account, password: password, captcha: captcha.passCode))
        )
    }

    func loginOtp(account: String, accountType: Int) -> Completable {
        httpClient.request(
            path: "api/auth/login/otp",
            method: .post,
            task: .requestJSONEncodable(LoginOtpRequest(account: account, loginAccountType: accountType))
        )
        .asCompletable()
    }

    func loginResendOtp() -> Completable {
        httpClient.request(
            path: "api/auth/login/resend-otp",
            method: .post,
            task: .requestPlain
        )
        .asCompletable()
    }

    func loginVerifyOtp(by verifyCode: String) -> Completable {
        httpClient.request(
            path: "api/auth/login/verify-otp",
            method: .post,
            task: .requestJSONEncodable(IVerifyOtpRequest(verifyCode: verifyCode))
        )
        .asCompletable()
    }

    func isLogged() -> Single<Bool> {
        httpClient.request(path: "api/auth/is-logged", method: .get)
    }

    func getCaptchaImage() -> Single<UIImage> {
        httpClient.requestImage(
            path: "api/auth/get-captcha-image",
            method: .get
        )
    }

    // MARK: 重置密碼

    func requestResetPassword(_ account: String, accountType: Int) -> Completable {
        httpClient.request(
            path: "api/forget-password",
            method: .post,
            task: .requestJSONEncodable(
                IResetPasswordRequest(
                    account: account,
                    accountType: accountType
                )
            )
        )
        .asCompletable()
    }

    func verifyResetOtp(_ params: IVerifyOtpRequest) -> Single<Bool> {
        httpClient.request(
            path: "api/forget-password/verify-otp",
            method: .post,
            task: .requestJSONEncodable(params)
        )
    }

    func changePassword(_ request: INewPasswordRequest) -> Completable {
        httpClient.request(
            path: "api/forget-password/change-password",
            method: .post,
            task: .requestJSONEncodable(request)
        )
        .asCompletable()
    }

    func resentOtp() -> Completable {
        httpClient.request(path: "api/forget-password/resend-otp", method: .post).asCompletable()
    }
}
