import Mockingbird
import XCTest

@testable import ktobet_asia_ios_qat

class XCBaseTestCase: XCTestCase {
  override func setUp() {
    super.setUp()

    Injection.shared.registerAllDependency()
    injectFakeHttpClient()
    injectStubPlayerLoginStatus()
    injectStubGetProductStatus()
    injectStubAppVersionUpdateUseCase()
  }
}

private func injectFakeHttpClient() {
  Injection.shared.container
    .register(HttpClient.self) { resolver in
      FakeHttpClient(
        resolver.resolveWrapper(LocalStorageRepository.self),
        resolver.resolveWrapper(KtoURL.self))
    }

  Injection.shared.container
    .register(HttpClient.self, name: "update") { resolver in
      FakeHttpClient(
        resolver.resolveWrapper(LocalStorageRepository.self),
        resolver.resolveWrapper(KtoURL.self, name: "update"))
    }
}

private func injectStubPlayerLoginStatus() {
  let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)

  given(stubAuthenticationUseCase.isLogged()) ~> .just(true)

  Injectable
    .register(AuthenticationUseCase.self) { _ in
      stubAuthenticationUseCase
    }
}

private func injectStubGetProductStatus() {
  let observeSystemMessageUseCase = mock(ObserveSystemMessageUseCase.self)

  given(observeSystemMessageUseCase.observeMaintenanceStatus(useCase: any())) ~> .just(.AllPortal(duration: 0))
  given(observeSystemMessageUseCase.errors()) ~> .never()

  Injectable
    .register(ObserveSystemMessageUseCase.self) { _ in
      observeSystemMessageUseCase
    }

  let getSystemStatusUseCase = mock(GetSystemStatusUseCase.self)

  given(getSystemStatusUseCase.fetchMaintenanceStatus()) ~> .never()
  given(getSystemStatusUseCase.getOtpStatus()) ~> .never()
  given(getSystemStatusUseCase.getCustomerServiceEmail()) ~> .never()
  given(getSystemStatusUseCase.observePortalMaintenanceState()) ~> .never()

  Injectable
    .register(GetSystemStatusUseCase.self) { _ in
      getSystemStatusUseCase
    }
}

private func injectStubAppVersionUpdateUseCase() {
  let appVersionUpdateUseCase = mock(AppVersionUpdateUseCase.self)

  given(appVersionUpdateUseCase.getLatestAppVersion()) ~> .just(.Companion().create(version: ""))
  given(appVersionUpdateUseCase.getSuperSignatureMaintenance()) ~> .never()

  Injectable
    .register(AppVersionUpdateUseCase.self) { _ in
      appVersionUpdateUseCase
    }
}
