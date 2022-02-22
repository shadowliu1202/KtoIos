//
//  PlayerApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/13.
//

import Foundation
import RxSwift
import Moya
import SwiftyJSON

class PlayerApi: ApiService {
    
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
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getPlayerInfo()-> Single<ResponseData<IPlayer>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/player-info",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<IPlayer>.self)
    }
    
    func getPlayerContact() -> Single<ResponseData<ContactInfoBean>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/contact-info",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<ContactInfoBean>.self)
    }
    
    func setFavoriteProduct(productId: Int)->Completable{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/favorite-product/\(productId)",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func getFavoriteProduct()->Single<Int>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/favorite-product",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map { (response) -> Int in
            guard let json = try? JSON(data: response.data),
                  let productType = json["data"].int else {
                return 0
            }
            return productType
        }
    }
    
    func getCashBalance() -> Single<ResponseData<Double>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/cash/balance",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Double>.self)
    }
    
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<ResponseData<[String: Double]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/cash/transaction-summary",
                               method: .get,
                               task: .requestParameters(parameters: ["createdDateRange.begin": begin,
                                                                     "createdDateRange.end": end,
                                                                     "balanceLogFilterType": balanceLogFilterType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[String: Double]>.self)
    }
    
    func isRealNameEditable() -> Single<ResponseData<Bool>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/realname-editable",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
    }
    
    func getPlayerLevel() -> Single<ResponseData<[LevelBean]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/level",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[LevelBean]>.self)
    }
    
    func getPlayerRealName() -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/profile/real-name",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getCultureCode() -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/culture",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getPlayerAffiliateStatus() -> Single<NonNullResponseData<Int32>>{
        let target = GetAPITarget(service: self.url("api/init/player-affiliate-status"))
        return httpClient.request(target).map(NonNullResponseData<Int32>.self)
    }
    
    // MARK: New
    func getCashLogSummary1(begin: String, end: String, balanceLogFilterType: Int) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/cash/transaction-summary",
                               method: .get,
                               task: .requestParameters(parameters: ["createdDateRange.begin": begin,
                                                                     "createdDateRange.end": end,
                                                                     "balanceLogFilterType": balanceLogFilterType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
}
