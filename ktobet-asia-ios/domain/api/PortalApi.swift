//
//  ProtalApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/16.
//

import Foundation
import RxSwift
import Moya

class PortalApi: ApiService {
    
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
    
    func getPortalMaintenance()->Single<ResponseData<OtpStatus>>{
        let target = GetAPITarget(service: self.url("api/init/portal-maintenance"))
        return httpClient.request(target).map(ResponseData<OtpStatus>.self)
    }
    
    func getLocalization() -> Single<ResponseData<ILocalizationData>> {
        let target = GetAPITarget(service: self.url("api/init/localization"))
        return httpClient.request(target).map(ResponseData<ILocalizationData>.self)
    }
    
    func initLocale(cultureCode: String) -> Completable {
        let target = PostAPITarget(service: self.url("api/init/culture/\(cultureCode)"))
        return httpClient.request(target).asCompletable()
    }
    
    func getProductStatus() -> Single<ResponseData<ProductStatusBean>>{
        let target = GetAPITarget(service: self.url("api/init/product-status"))
        return httpClient.request(target).map(ResponseData<ProductStatusBean>.self)
    }
    
    func getCustomerServiceEmail() -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/profile/cs-mail",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getIOSVersion() -> Single<NonNullResponseData<VersionData>> {
        let target = GetAPITarget(service: self.url("ios/api/get-ios-ipa-version"))
        return httpClient.request(target).map(NonNullResponseData<VersionData>.self)
    }
    
    func getCryptoTutorials() -> Single<ResponseData<[CryptoTutorialBean]>> {
        let target = GetAPITarget(service: self.url("api/crypto/exchange-tutorials"))
        return httpClient.request(target).map(ResponseData<[CryptoTutorialBean]>.self)
    }
    
    func getYearOfCopyRight() -> Single<NonNullResponseData<String>> {
        let target = GetAPITarget(service: self.url("api/init/license"))
        return httpClient.request(target).map(NonNullResponseData<String>.self)
    }
    
    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
        let target = GetAPITarget(service: self.url("api/download-ios-maintenance"))
        return httpClient.request(target).map(SuperSignMaintenanceBean.self)
    }
}
