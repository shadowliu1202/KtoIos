import Foundation
import Moya
import RxSwift

class FakeHttpClient: HttpClient {
  override func request(_: Moya.TargetType) -> RxSwift.Single<Response> {
    fatalError("Should not reach here.")
  }

  override func requestJsonString(_: Moya.TargetType) -> RxSwift.Single<String> {
    fatalError("Should not reach here.")
  }
  
  override func requestJsonString(path _: String, method _: Moya.Method, task _: Task? = nil) -> Single<String> {
    fatalError("should not reach here.")
  }
}
