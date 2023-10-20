import Mockingbird
import Moya
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class HttpClientTests: XCTestCase {
  let dummyURL = URL(string: "https://")!
  
  lazy var dummyTargetType = NewAPITarget(path: "", method: .get, baseURL: dummyURL, headers: [:])
  
  func test_givenResponseDataWithoutStatusCodeAndErrorMsg_thenStillReceiveResponse() async {
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyCookieManager = mock(CookieManager.self).initialize(allHosts: [], currentURL: dummyURL, currentDomain: "")
    
    let stubResponse = Moya.Response(
      statusCode: 200,
      data: MaintenanceStatus(endTime: 0, isMaintenance: false).toData())
    
    let stubProvider = FakeMoyaProvider(stubRequest: .success(stubResponse))
    
    let sut = HttpClient(
      dummyLocalStorageRepo,
      dummyCookieManager,
      currentURL: dummyURL,
      provider: stubProvider)
    
    let expect = stubResponse
    let actual = try! await sut.request(dummyTargetType).value
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenResponseDataWithEmptyStatusCode_thenReceiveResponse() async {
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyCookieManager = mock(CookieManager.self).initialize(allHosts: [], currentURL: dummyURL, currentDomain: "")
    
    let stubResponse = Moya.Response(
      statusCode: 200,
      data: APIResult(statusCode: "", errorMsg: "").toData())
    
    let stubProvider = FakeMoyaProvider(stubRequest: .success(stubResponse))
    
    let sut = HttpClient(
      dummyLocalStorageRepo,
      dummyCookieManager,
      currentURL: dummyURL,
      provider: stubProvider)
    
    let expect = stubResponse
    let actual = try! await sut.request(dummyTargetType).value
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenResponseDataWithEmptyStatusCode_thenReceiveApiException() async {
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyCookieManager = mock(CookieManager.self).initialize(allHosts: [], currentURL: dummyURL, currentDomain: "")
    
    let stubResponse = Moya.Response(
      statusCode: 200,
      data: APIResult(statusCode: "99999", errorMsg: "testErrorMessage").toData())
    
    let stubProvider = FakeMoyaProvider(stubRequest: .success(stubResponse))
    
    let sut = HttpClient(
      dummyLocalStorageRepo,
      dummyCookieManager,
      currentURL: dummyURL,
      provider: stubProvider)
    
    let expect = UnknownError(message: "testErrorMessage", errorCode: "99999")
    var actual = ApiException(message: nil, errorCode: nil)
    
    do {
      _ = try await sut.request(dummyTargetType).value
    }
    catch {
      actual = error as! ApiException
    }
    
    XCTAssertEqual(expect, actual)
  }
}

private struct MaintenanceStatus: Codable {
  var endTime: Int
  var isMaintenance: Bool
  
  func toData() -> Data {
    try! JSONEncoder().encode(self)
  }
}

private struct APIResult: Codable {
  var statusCode: String
  var errorMsg: String
  
  func toData() -> Data {
    try! JSONEncoder().encode(self)
  }
}

class FakeMoyaProvider: MoyaProvider<MultiTarget> {
  let stubRequest: Result<Response, MoyaError>
  
  init(stubRequest: Result<Response, MoyaError>) {
    self.stubRequest = stubRequest
    super.init()
  }
  
  override func request(
    _: MultiTarget,
    callbackQueue _: DispatchQueue? = .none,
    progress _: ProgressBlock? = .none,
    completion: @escaping Completion)
    -> Cancellable
  {
    completion(stubRequest)
    return CancellableToken(action: { })
  }
}
