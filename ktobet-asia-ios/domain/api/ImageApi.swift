import Foundation
import RxSwift
import SharedBu
import Moya
import SwiftyJSON

class ImageApi {
    private var httpClient: HttpClient!
    
    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
    
    func getPrivateImageToken(imageId: String) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/image/hash/\(imageId)",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func uploadImage(query: [String: Any], imageData: [MultipartFormData]) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/image/upload",
                               method: .post,
                               task: .uploadCompositeMultipart(imageData, urlParameters: query),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    // MARK: New
    func getPrivateImageToken(imageId: String) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/image/hash/\(imageId)",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
}
