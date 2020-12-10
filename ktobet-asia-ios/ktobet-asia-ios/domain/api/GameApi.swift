//
//  GameApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/18.
//

import Foundation
import RxSwift
import SwiftyJSON
import Moya


class GameApi{
    
    private var httpClient : HttpClient!

    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getGameUrl()->Single<URL>{
        let para = ["siteUrl":httpClient.host]
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "casino/api/game/url/55",
                               method: .get,
                               task: .requestParameters(parameters: para, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target)
            .map(ResponseData<String>.self)
            .map({response -> URL in
                let path = response.data
                return URL(string: path!)!
            })
    }
}

