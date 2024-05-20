import Foundation
import Moya

@available(*, deprecated, message: "Use NewAPITarget instead")
class APITarget: TargetType {
    //
    var baseURL: URL { iBaseUrl }
    var path: String { iPath }
    var method: Moya.Method { iMethod }
    var sampleData: Data { iSamepleData }
    var task: Task { iTask }
    var headers: [String: String]? { iHeaders }
    //
    var iBaseUrl: URL!
    var iPath: String!
    var iMethod: Moya.Method!
    var iSamepleData = Data()
    var iTask: Task!
    var iHeaders: [String: String]?
    var para: Encodable?

    init(baseUrl: URL, path: String, method: Moya.Method, task: Task, header: [String: String]?) {
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
    var headers: [String: String]? { get }
    var baseUrl: URL { get }
}

@available(*, deprecated, message: "Use NewAPITarget instead")
class GetAPITarget: APITarget {
    init(service: ApiService, task: Task = .requestPlain) {
        super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .get, task: task, header: service.headers)
    }

    @available(*, deprecated, message: "Use NewAPITarget instead")
    func parameters(_ parameters: [String: Any]) -> Self {
        self.iTask = .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        return self
    }
}

@available(*, deprecated, message: "Use NewAPITarget instead")
class PutAPITarget: APITarget {
    init(service: ApiService, parameters: Encodable) {
        super.init(
            baseUrl: service.baseUrl,
            path: service.surfixPath,
            method: .put,
            task: .requestJSONEncodable(parameters),
            header: service.headers)
    }
}

@available(*, deprecated, message: "Use NewAPITarget instead")
class PostAPITarget: APITarget {
    init(service: ApiService, parameters: Encodable? = nil) {
        if let parameters {
            super.init(
                baseUrl: service.baseUrl,
                path: service.surfixPath,
                method: .post,
                task: .requestJSONEncodable(parameters),
                header: service.headers)
        }
        else {
            super.init(
                baseUrl: service.baseUrl,
                path: service.surfixPath,
                method: .post,
                task: .requestPlain,
                header: service.headers)
        }
    }
}

@available(*, deprecated, message: "Use NewAPITarget instead")
class DeleteAPITarget: APITarget {
    init(service: ApiService, task: Task = .requestPlain) {
        super.init(baseUrl: service.baseUrl, path: service.surfixPath, method: .delete, task: task, header: service.headers)
    }

    func parameters(_ parameters: [String: Any]) -> Self {
        self.iTask = .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        return self
    }
}

// MARK: - NewAPITarget

class NewAPITarget: TargetType {
    let baseURL: URL
    let path: String
    var method: Moya.Method
    var task: Moya.Task = .requestPlain
    let headers: [String: String]?

    @available(
        *,
        deprecated,
        message: "Use init(path: String, method: Moya.Method, task: Moya.Task?, baseURL: URL, headers: [String: String]) instead")
    init(
        path: String,
        method: Moya.Method,
        task: Moya.Task? = nil)
    {
        let httpClient = Injectable.resolveWrapper(HttpClient.self)

        self.baseURL = httpClient.host
        self.headers = httpClient.headers
        self.path = path
        self.method = method

        if let task {
            self.task = task
        }
    }
  
    init(
        path: String,
        method: Moya.Method,
        task: Moya.Task? = nil,
        baseURL: URL,
        headers: [String: String])
    {
        self.baseURL = baseURL
        self.headers = headers
        self.path = path
        self.method = method

        if let task {
            self.task = task
        }
    }
}

extension Moya.Task {
    static func requestParameters(parameters: [String: Any]) -> Moya.Task {
        .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
}
