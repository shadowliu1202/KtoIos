//
//  TargetTypeBuilder.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/20.
//

import Foundation
import Moya

class APITarget : TargetType{
    //
    var baseURL: URL { return iBaseUrl}
    var path: String { return iPath}
    var method: Moya.Method { return iMethod}
    var sampleData: Data { return iSamepleData}
    var task: Task { return iTask}
    var headers: [String : String]? {return iHeaders}
    //
    var iBaseUrl : URL!
    var iPath : String!
    var iMethod : Moya.Method!
    var iSamepleData = Data()
    var iTask : Task!
    var iHeaders : [String : String]?
    var para : Encodable?
    
    init(baseUrl: URL, path: String, method:Moya.Method, task: Task, header : [String:String]?) {
        self.iBaseUrl = baseUrl
        self.iPath = path
        self.iMethod = method
        self.iSamepleData = sampleData
        self.iTask = task
        self.iHeaders = header
    }
}

protocol ApiService {
    var surfixPath: String { get }
    var headers : [String : String]? { get }
    var baseUrl : URL { get }
}

class GetAPITarget: APITarget {
    init(service: ApiService, task: Task = .requestPlain) {
        super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .get, task: task, header: service.headers)
    }
    
    func parameters(_ parameters: [String: Any]) -> Self {
        self.iTask = .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        return self
    }
}

class PutAPITarget: APITarget {
    init(service: ApiService, parameters: Encodable) {
        super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .put, task: .requestJSONEncodable(parameters), header: service.headers)
    }
}

class PostAPITarget: APITarget {
    init(service: ApiService, parameters: Encodable? = nil) {
        if let parameters = parameters {
            super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .post, task: .requestJSONEncodable(parameters), header: service.headers)
        } else {
            super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .post, task: .requestPlain, header: service.headers)
        }
    }
}

class DeleteAPITarget: APITarget {
    init(service: ApiService, task: Task = .requestPlain) {
        super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .delete, task: task, header: service.headers)
    }
    
    func parameters(_ parameters: [String: Any]) -> Self {
        self.iTask = .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        return self
    }
}
