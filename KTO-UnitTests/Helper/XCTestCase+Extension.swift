import XCTest
import Mockingbird
import RxSwift

@testable import ktobet_asia_ios_qat

extension XCTestCase {
    func test<T>(_ description: String, block: () throws -> T) rethrows -> T {
        try XCTContext.runActivity(named: description, block: { _ in try block() })
    }
    
    func stubHttpClientRequest(responseJsonString: String) -> HttpClientMock {
        let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
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
        let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
        let dummyKtoURL = mock(KtoURL.self)
        
        return mock(HttpClient.self).initialize(dummyLocalStorageRepo, dummyKtoURL)
    }
    
    func injectStubCultureCode(_ language: Language) {
        let stubLocalStorageRepository = mock(LocalStorageRepository.self)
        
        given(stubLocalStorageRepository.getCultureCode()) ~> language.rawValue
        
        Localize = LocalizeUtils(localStorageRepo: stubLocalStorageRepository)
    }
    
    func injectStubPlayerLoginStatus(isLogin: Bool = true) {
        let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)
        
        given(stubAuthenticationUseCase.isLogged()) ~> .just(isLogin)
        
        Injectable
            .register(AuthenticationUseCase.self) { resolver in
                return stubAuthenticationUseCase
            }
    }
    
    func makeItVisible(_ target: UIViewController) {
        let keyWindow = (UIApplication.shared.delegate as? AppDelegate)?.window
        keyWindow?.rootViewController = target
        keyWindow?.makeKeyAndVisible()
    }
}
