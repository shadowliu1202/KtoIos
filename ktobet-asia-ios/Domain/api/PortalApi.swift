import Foundation
import Moya
import RxSwift

class PortalApi {
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getPortalMaintenance() -> Single<OtpStatus?> {
        httpClient.request(path: "api/init/portal-maintenance", method: .get)
    }

    func getOtpMaintenance() -> Single<OtpStatus?> {
        httpClient.request(path: "api/init/otp-maintenance", method: .get)
    }

    func getLocalization() -> Single<ILocalizationData?> {
        httpClient.request(path: "api/init/localization", method: .get)
    }

    func initLocale(cultureCode: String) -> Completable {
        httpClient.request(path: "api/init/culture/\(cultureCode)", method: .post).asCompletable()
    }

    func getProductStatus() -> Single<ProductStatusBean?> {
        httpClient.request(path: "api/init/product-status", method: .get)
    }

    func getCustomerServiceEmail() -> Single<String?> {
        httpClient.request(path: "api/profile/cs-mail", method: .get)
    }

    func getCryptoTutorials() -> Single<[CryptoTutorialBean]?> {
        httpClient.request(path: "api/crypto/exchange-tutorials", method: .get)
    }

    func getYearOfCopyRight() -> Single<String> {
        return httpClient.request(path: "api/init/license", method: .get)
    }
}
