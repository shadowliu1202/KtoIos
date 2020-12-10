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

class PlayerApi {
    
    private var httpClient : HttpClient!
    
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
}
