import Foundation
import Moya
import RxSwift
import sharedbu
import SwiftyJSON

protocol ImageApiProtocol {
    func uploadImage(query: [String: Any], imageData: [MultipartFormData]) -> Single<String?>
}

class ImageApi {
    private var httpClient: HttpClient!

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getPrivateImageToken(imageId: String) -> SingleWrapper<ResponseItem<NSString>> {
        httpClient.request(path: "api/image/hash/\(imageId)", method: .get).asReaktiveResponseItem()
    }

    // MARK: New

    func getPrivateImageToken(imageId: String) -> Single<String> {
        return httpClient.request(path: "api/image/hash/\(imageId)", method: .get)
    }
}

extension ImageApi: ImageApiProtocol {
    func uploadImage(query: [String: Any], imageData: [MultipartFormData]) -> Single<String?> {
        return httpClient.request(path: "api/image/upload", method: .post, task: .uploadCompositeMultipart(imageData, urlParameters: query))
    }
}
