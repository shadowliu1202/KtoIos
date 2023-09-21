import Alamofire
import Moya
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class APPErrorTests: XCTestCase {
  struct DummyError: Error { }
  
  private func moyaDomainNSError(statusCode: Int) -> NSError {
    NSError(domain: "MoyaError", code: statusCode, userInfo: [
      "ErrorDescription": "Status code didn't fall within the given range.",
      "ResponseBody": ""
    ])
  }
  
  override func setUp() {
    Injection.shared.container
      .register(ActivityIndicator.self, name: "CheckingIsLogged") { _ in
        .init()
      }
      .inObjectScope(.application)
  }
  
  func test_givenSharedBuError_whenGenerateResult_thenResultIsUnknownError() {
    let stubError = ApiException(message: "Test", errorCode: "1234")
    let actual = APPError.convert(by: stubError)
    
    let expect = APPError.unknown(
      NSError(
        domain: "ApiException",
        code: 1234,
        userInfo: [
          "StatusCode": "1234",
          "ErrorMessage": "Test",
          "ExceptionName": "SharedBuApiException"
        ]))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenExplicitlyCancelledError_whenGenerateResult_thenResultIsDoNothing() {
    let stubError = MoyaError.underlying(AFError.explicitlyCancelled, nil)
    let actual = APPError.convert(by: stubError)
    
    let expect = APPError.ignorable
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenMoyaMappingError_whenGenerateResult_thenResultIsWrongFormat() {
    let dummyError = DummyError()
    let dummyResponse = Response(statusCode: 0, data: Data())
    
    let stubErrors: [MoyaError] = [
      .encodableMapping(dummyError),
      .imageMapping(dummyResponse),
      .jsonMapping(dummyResponse),
      .objectMapping(dummyError, dummyResponse),
      .stringMapping(dummyResponse)
    ]
    
    var actual = 0
    
    for stubError in stubErrors {
      guard APPError.convert(by: stubError) == .wrongFormat else { return }
      actual += 1
    }
    
    let expect = 5
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given401MoyaErrorAndIsLoading_whenGenerateResult_thenResultIsDoNothing() {
    @Injected(name: "CheckingIsLogged") var tracker: ActivityIndicator
    
    let stubLoadingAPI = Single<Bool>.never().trackOnDispose(tracker).subscribe()
    let stubError = MoyaError.statusCode(.init(statusCode: 401, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.ignorable
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given401MoyaErrorAndNotLoading_whenGenerateResult_thenResultIsUnknownError() {
    @Injected(name: "CheckingIsLogged") var tracker: ActivityIndicator
    
    let stubError = MoyaError.statusCode(.init(statusCode: 401, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(moyaDomainNSError(statusCode: 401))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given403MoyaError_whenGenerateResult_thenResultIsRegionRestricted() {
    let stubError = MoyaError.statusCode(.init(statusCode: 403, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.regionRestricted
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given404MoyaError_whenGenerateResult_thenResultIsUnknownError() {
    let stubError = MoyaError.statusCode(.init(statusCode: 404, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(moyaDomainNSError(statusCode: 404))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given410MoyaError_whenGenerateResult_thenResultIsMaintenance() {
    let stubError = MoyaError.statusCode(.init(statusCode: 410, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.maintenance
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given429MoyaError_whenGenerateResult_thenResultIsTooManyRequest() {
    let stubError = MoyaError.statusCode(.init(statusCode: 429, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.tooManyRequest
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given502MoyaError_whenGenerateResult_thenResultIsUnknownError() {
    let stubError = MoyaError.statusCode(.init(statusCode: 502, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(moyaDomainNSError(statusCode: 502))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given503MoyaError_whenGenerateResult_thenResultIsTemporaryError() {
    let stubError = MoyaError.statusCode(.init(statusCode: 503, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.temporary
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_given608MoyaError_whenGenerateResult_thenResultIsCDNError() {
    let stubError = MoyaError.statusCode(.init(statusCode: 608, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.cdn
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenNotHandleStatusMoyaError_whenGenerateResult_thenResultIsIsUnknownError() {
    let stubError = MoyaError.statusCode(.init(statusCode: 1000, data: .init()))
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(moyaDomainNSError(statusCode: 1000))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenResponseParseError_whenGenerateResult_thenResultIsIsUnknownError() {
    let stubError = ResponseParseError(rawData: .init())
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(
      NSError(
        domain: "ResponseParseError",
        code: -3,
        userInfo: ["RawData": Data()]))
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenUnexpectedError_whenGenerateResult_thenResultIsIsUnknownError() {
    let stubError = KTOError.JsonParseError
    
    let actual = APPError.convert(by: stubError)
    let expect = APPError.unknown(
      NSError(domain: "ktobet_asia_ios_qat.KTOError", code: 4))
    
    XCTAssertEqual(expect, actual)
  }
}
