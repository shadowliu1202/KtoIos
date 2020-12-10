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
