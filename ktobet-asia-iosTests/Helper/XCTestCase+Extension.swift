import XCTest
import Mockingbird
import RxSwift

@testable import ktobet_asia_ios_qat

extension XCTestCase {
    func test<T>(_ description: String, block: () throws -> T) rethrows -> T {
        try XCTContext.runActivity(named: description, block: { _ in try block() })
    }
    
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")
        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: duration + 0.5)
    }
    
    func stubHttpClientRequest(responseJsonString: String) -> HttpClientMock {
        
        let dummyLocalStorageRepo = mock(LocalStorageRepository.self).initialize("")
        let dummyKtoURL = mock(KtoURL.self)
        
        let apiResponse = Response(
            statusCode: 200,
            data: responseJsonString.data(using: .utf8)!
        )
        
        let stubHttpClient = mock(HttpClient.self).initialize(dummyLocalStorageRepo, dummyKtoURL)
        given(stubHttpClient.host) ~> URL(string: "https://")!
        given(stubHttpClient.headers) ~> ["": ""]
        given(stubHttpClient.request(any())) ~> .just(apiResponse)
        
        return stubHttpClient
    }
    
    func getFakeHttpClient() -> HttpClientMock {
        let dummyLocalStorageRepo = mock(LocalStorageRepository.self).initialize("")
        let dummyKtoURL = mock(KtoURL.self)
        
        return mock(HttpClient.self).initialize(dummyLocalStorageRepo, dummyKtoURL)
    }
    
    func stubCultureCode(_ code: String = "zh-cn") {
        let stubLocalStorageRepository = mock(LocalStorageRepository.self).initialize(nil)
        given(stubLocalStorageRepository.getCultureCode()) ~> code
        
        Injectable
            .register(LocalizeUtils.self) { resolver in
                return LocalizeUtils(localStorageRepo: stubLocalStorageRepository)
            }
    }
    
    func injectStubAuthenticationUseCase(isLogin: Bool = true) {
        let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)
        
        given(stubAuthenticationUseCase.isLogged()) ~> .just(isLogin)
        
        Injectable
            .register(AuthenticationUseCase.self) { resolver in
                return stubAuthenticationUseCase
            }
    }
}
