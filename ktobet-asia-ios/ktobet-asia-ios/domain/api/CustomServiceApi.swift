//
//  CustomServiceApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/18.
//

import Foundation
import RxSwift
import SwiftyJSON
import Moya


class CustomServiceApi{
    
    private var httpClient : HttpClient!

    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getSkillSurveyId()->Single<String>{
        let para = ["surveyType" : 0, "platForm" : 2]
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/auth/login",
                               method: .get,
                               task: .requestParameters(parameters: para, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target)
            .map(ResponseData<SkillData>.self)
            .map { (response) -> String in
                return response.data?.skillId ?? ""
            }
    }
    
    func getSocketToken(_ skillId : String)-> Single<String>{
        let para = ["skillId":skillId]
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/pchat/create-token",
                               method: .get,
                               task: .requestParameters(parameters: para, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target)
            .map(ResponseData<String>.self)
            .map { (response) -> String in
                return response.data ?? ""
            }
    }
    
    func checkToken()->Single<String>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "onlinechat/api/common/check",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target)
            .map(ResponseData<String>.self)
            .map { (response) -> String in
                return response.data ?? ""
            }
    }
}
