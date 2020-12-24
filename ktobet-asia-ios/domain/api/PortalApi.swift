//
//  ProtalApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/16.
//

import Foundation
import RxSwift
import Moya

class PortalApi{
    
    private var httpClient : HttpClient!

    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getPortalMaintenance()->Single<ResponseData<OtpStatus>>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/portal-maintenance",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<OtpStatus>.self)
    }
    
    func getLocalization()->Single<ResponseData<ILocalizationData>>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/localization",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<ILocalizationData>.self)
    }
}
