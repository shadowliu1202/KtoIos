import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

class XCBaseTestCase: XCTestCase, StubProvidable {
    override func setUp() {
        super.setUp()

        Injection.shared.registerAllDependency()
        injectFakeHttpClient()
        injectStubPlayerLoginStatus()
        injectStubGetProductStatus()
        injectStubAppVersionUpdateUseCase()
        injectCustomServicePresenterInfra()
    }
}

private func injectFakeHttpClient() {
    Injection.shared.container
        .register(HttpClient.self) { resolver in
            HttpClient(
                resolver.resolveWrapper(LocalStorageRepository.self),
                resolver.resolveWrapper(CookieManager.self),
                currentURL: URL(string: "https://")!,
                locale: resolver.resolveWrapper(PlayerConfiguration.self).supportLocale)
        }

    Injection.shared.container
        .register(HttpClient.self, name: "update") { resolver in
            HttpClient(
                resolver.resolveWrapper(LocalStorageRepository.self),
                resolver.resolveWrapper(CookieManager.self),
                currentURL: URL(string: "https://")!,
                locale: resolver.resolveWrapper(PlayerConfiguration.self).supportLocale)
        }
}

private func injectStubPlayerLoginStatus() {
    let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)

    given(stubAuthenticationUseCase.isLogged()) ~> .just(true)
    given(stubAuthenticationUseCase.accountValidation()) ~> .just(true)

    Injectable
        .register(AuthenticationUseCase.self) { _ in
            stubAuthenticationUseCase
        }
}

private func injectStubGetProductStatus() {
    let systemStatusUseCase = mock(ISystemStatusUseCase.self)

    given(systemStatusUseCase.fetchMaintenanceStatus()) ~> .never()
    given(systemStatusUseCase.isOtpBlocked()) ~> .never()
    given(systemStatusUseCase.isOtpServiceAvaiable()) ~> .never()
    given(systemStatusUseCase.fetchCustomerServiceEmail()) ~> .never()
    given(systemStatusUseCase.observeMaintenanceStatusByFetch()) ~> .never()
    given(systemStatusUseCase.observeMaintenanceStatusChange()) ~> .never()

    Injectable
        .register(ISystemStatusUseCase.self) { _ in
            systemStatusUseCase
        }
}

private func injectStubAppVersionUpdateUseCase() {
    let appVersionUpdateUseCase = mock(AppVersionUpdateUseCase.self)

    given(appVersionUpdateUseCase.getLatestAppVersion()) ~> .just(.companion.create(version: "0.0.1", link: "", size: 0.0))
    given(appVersionUpdateUseCase.getSuperSignatureMaintenance()) ~> .never()

    Injectable
        .register(AppVersionUpdateUseCase.self) { _ in
            appVersionUpdateUseCase
        }
}

private func injectCustomServicePresenterInfra() {
    let stubChatAppService = mock(AbsCustomerServiceAppService.self)
    let dummySurveyAppService = mock(AbsCustomerServiceAppService.self)
    let dummyLoading = LoadingImpl.shared

    given(stubChatAppService.observeChatRoom()) ~> Observable.just(CustomerServiceDTO.ChatRoom.NOT_EXIST).asWrapper()
    
    let stubCustomerServiceViewModel = mock(CustomerServiceViewModel.self)
        .initialize(stubChatAppService, dummySurveyAppService, dummyLoading)
  
    Injectable
        .register(CustomerServiceViewModel.self) { _ in
            stubCustomerServiceViewModel
        }
        .inObjectScope(.locale)
}
