import Foundation
import sharedbu

class DefaultProductAdapter: DefaultProductProtocol {
    private let httpClient: HttpClient
  
    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
  
    func getFavoriteProduct() -> SingleWrapper<ResponseItem<KotlinInt>> {
        httpClient
            .request(path: "api/profile/favorite-product", method: .get)
            .asReaktiveResponseItem { (number: NSNumber) -> KotlinInt in
                KotlinInt(int: number.int32Value)
            }
    }
  
    func setFavoriteProduct(productId: Int32) -> CompletableWrapper {
        httpClient
            .request(
                path: "api/profile/favorite-product/\(productId)",
                method: .post)
            .asReaktiveCompletable()
    }
}
