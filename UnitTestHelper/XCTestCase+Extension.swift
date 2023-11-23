import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

func XCTAssertEqual<E: Equatable>(expect: E, actual: E) {
  XCTAssertEqual(expect, actual)
}

extension XCTestCase {
  func test<T>(_ description: String, block: () throws -> T) rethrows -> T {
    try XCTContext.runActivity(named: description, block: { _ in try block() })
  }

  func stubHttpClientRequest(responseJsonString: String) -> HttpClientMock {
    let dummyURL = URL(string: "https://")!
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyCookieManager = mock(CookieManager.self).initialize(allHosts: [], currentURL: dummyURL, currentDomain: "")

    let apiResponse = Response(
      statusCode: 200,
      data: responseJsonString.data(using: .utf8)!)

    let stubHttpClient = mock(HttpClient.self)
      .initialize(dummyLocalStorageRepo, dummyCookieManager, currentURL: dummyURL, provider: nil)
    given(stubHttpClient.host) ~> URL(string: "https://")!
    given(stubHttpClient.headers) ~> ["": ""]
    given(stubHttpClient.request(any())) ~> .just(apiResponse)

    return stubHttpClient
  }

  func getFakeHttpClient() -> HttpClientMock {
    let dummyURL = URL(string: "https://")!
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyCookieManager = mock(CookieManager.self).initialize(allHosts: [], currentURL: dummyURL, currentDomain: "")

    return mock(HttpClient.self).initialize(dummyLocalStorageRepo, dummyCookieManager, currentURL: dummyURL, provider: nil)
  }

  @available(*, deprecated, message: "Use injectLocalStorageRepository().")
  func injectStubCultureCode(_ language: Language) {
    Localize = LocalizeUtils(localizationFileName: language.rawValue)
  }
  
  func injectLocalStorageRepository(_ supportLocale: SupportLocale) {
    let stubLocalStorageRepository = mock(LocalStorageRepository.self)

    given(stubLocalStorageRepository.getSupportLocale()) ~> supportLocale
    
    let cultureCode = {
      switch supportLocale {
      case is SupportLocale.China:
        return "zh-cn"
      case is SupportLocale.Vietnam:
        return "vi-vn"
      default:
        return "vi-vn"
      }
    }()
    
    given(stubLocalStorageRepository.getCultureCode()) ~> cultureCode
    
    Injectable.register(LocalStorageRepository.self) { _ in
      stubLocalStorageRepository
    }
  }

  func makeItVisible(_ target: UIViewController) {
    let keyWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
    keyWindow?.rootViewController = target
    keyWindow?.makeKeyAndVisible()
    keyWindow?.layoutIfNeeded()
  }
  
  func injectFakeObject<T>(_ objectType: T.Type, object: T) {
    Injectable.register(objectType) { _ in object }
  }
}
