import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class KtoURLManagerTests: XCBaseTestCase {
  let internetProtocol = "https://"
  
  func test_givenPortalAndVersionUpdateCheckSuccess_thenGetEachFastestURL() async {
    let stubURLSession = FakeURLSession(internetProtocol)
    stubURLSession.given(host: "B", delaySeconds: 0.001)
    stubURLSession.given(host: "A", delaySeconds: 0.01)
    stubURLSession.given(host: "C", delaySeconds: 0.15)
    stubURLSession.given(host: "D", delaySeconds: 0.2)
    
    stubURLSession.given(host: "G", delaySeconds: 0.001)
    stubURLSession.given(host: "H", delaySeconds: 0.01)
    stubURLSession.given(host: "E", delaySeconds: 0.15)
    stubURLSession.given(host: "F", delaySeconds: 0.2)
    
    let sut = KtoURLManager(
      timeout: 0.1,
      portalHosts: ["A", "B", "C", "D"],
      versionUpdateHosts: ["E", "F", "G", "H"],
      internetProtocol: internetProtocol,
      urlSession: stubURLSession)
    
    await sut.checkHosts()
    
    let expect1 = "https://B/"
    let actual1 = sut.portalURL.absoluteString
    
    let expect2 = "https://G/"
    let actual2 = sut.versionUpdateURL.absoluteString
    
    XCTAssertEqual(expect1, actual1)
    XCTAssertEqual(expect2, actual2)
  }
  
  func test_givenPortalAndVersionUpdateCheckTimeoutOrFail_thenGetEachDefaultURL() async {
    let stubURLSession = FakeURLSession(internetProtocol)
    stubURLSession.given(host: "B", isSuccess: false, delaySeconds: 0.001)
    stubURLSession.given(host: "A", isSuccess: false, delaySeconds: 0.01)
    stubURLSession.given(host: "C", delaySeconds: 0.15)
    stubURLSession.given(host: "D", delaySeconds: 0.2)
    
    stubURLSession.given(host: "G", isSuccess: false, delaySeconds: 0.001)
    stubURLSession.given(host: "H", isSuccess: false, delaySeconds: 0.01)
    stubURLSession.given(host: "E", delaySeconds: 0.15)
    stubURLSession.given(host: "F", delaySeconds: 0.2)
    
    let sut = KtoURLManager(
      timeout: 0.1,
      portalHosts: ["A", "B", "C", "D"],
      versionUpdateHosts: ["E", "F", "G", "H"],
      internetProtocol: internetProtocol,
      urlSession: stubURLSession)
    
    await sut.checkHosts()
    
    let expect1 = "https://A/"
    let actual1 = sut.portalURL.absoluteString
    
    let expect2 = "https://E/"
    let actual2 = sut.versionUpdateURL.absoluteString
    
    XCTAssertEqual(expect1, actual1)
    XCTAssertEqual(expect2, actual2)
  }
  
  func test_givenPortalCheckSuccessButVersionUpdateCheckTimeoutOrFail_thenGetPortalFastestURLAndVersionUpdateDefaultURL() async {
    let stubURLSession = FakeURLSession(internetProtocol)
    stubURLSession.given(host: "B", delaySeconds: 0.001)
    stubURLSession.given(host: "A", delaySeconds: 0.01)
    stubURLSession.given(host: "C", delaySeconds: 0.15)
    stubURLSession.given(host: "D", delaySeconds: 0.2)
    
    stubURLSession.given(host: "G", isSuccess: false, delaySeconds: 0.001)
    stubURLSession.given(host: "H", isSuccess: false, delaySeconds: 0.01)
    stubURLSession.given(host: "E", delaySeconds: 0.15)
    stubURLSession.given(host: "F", delaySeconds: 0.2)
    
    let sut = KtoURLManager(
      timeout: 0.1,
      portalHosts: ["A", "B", "C", "D"],
      versionUpdateHosts: ["E", "F", "G", "H"],
      internetProtocol: internetProtocol,
      urlSession: stubURLSession)
    
    await sut.checkHosts()
    
    let expect1 = "https://B/"
    let actual1 = sut.portalURL.absoluteString
    
    let expect2 = "https://E/"
    let actual2 = sut.versionUpdateURL.absoluteString
    
    XCTAssertEqual(expect1, actual1)
    XCTAssertEqual(expect2, actual2)
  }
  
  func test_givenVersionUpdateCheckSuccessButPortalCheckTimeoutOrFail_thenGetVersionUpdateFastestURLAndPortalDefaultURL() async {
    let stubURLSession = FakeURLSession(internetProtocol)
    stubURLSession.given(host: "B", isSuccess: false, delaySeconds: 0.001)
    stubURLSession.given(host: "A", isSuccess: false, delaySeconds: 0.01)
    stubURLSession.given(host: "C", delaySeconds: 0.15)
    stubURLSession.given(host: "D", delaySeconds: 0.2)
    
    stubURLSession.given(host: "G", delaySeconds: 0.001)
    stubURLSession.given(host: "H", delaySeconds: 0.01)
    stubURLSession.given(host: "E", delaySeconds: 0.15)
    stubURLSession.given(host: "F", delaySeconds: 0.2)
    
    let sut = KtoURLManager(
      timeout: 0.1,
      portalHosts: ["A", "B", "C", "D"],
      versionUpdateHosts: ["E", "F", "G", "H"],
      internetProtocol: internetProtocol,
      urlSession: stubURLSession)
    
    await sut.checkHosts()
    
    let expect1 = "https://A/"
    let actual1 = sut.portalURL.absoluteString
    
    let expect2 = "https://G/"
    let actual2 = sut.versionUpdateURL.absoluteString
    
    XCTAssertEqual(expect1, actual1)
    XCTAssertEqual(expect2, actual2)
  }
}

class FakeURLSession: URLSessionProtocol {
  struct StubCondition: Hashable {
    let host: String
    let isSuccess: Bool
    let delaySeconds: Double
  }
  
  private let internetProtocol: String
  
  private var conditions: Set<StubCondition> = []
  
  init(_ internetProtocol: String) {
    self.internetProtocol = internetProtocol
  }
  
  func given(host: String, isSuccess: Bool = true, delaySeconds: Double) {
    conditions.insert(.init(host: "\(internetProtocol)\(host)/", isSuccess: isSuccess, delaySeconds: delaySeconds))
  }
  
  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    let condition = conditions.first(where: { request.url!.absoluteString == $0.host })!
    
    try await Task.sleep(seconds: condition.delaySeconds)
    
    guard condition.isSuccess else { throw KTOError.EmptyData }
    
    return (Data(), HTTPURLResponse(url: URL(string: "https://")!, statusCode: 200, httpVersion: nil, headerFields: [:])!)
  }
}
