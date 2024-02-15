import Foundation
import RxSwift
import sharedbu
import Swinject
import SwinjectAutoregistration

final class Injection {
  static let shared = Injection()

  private(set) var container = Container()
  private let assembler: Assembler

  let networkReadyRelay = BehaviorRelay(value: false)
  
  private init() {
    HelperKt.doInitKoin()
    assembler = Assembler(container: container)
    registerAllDependency()
  }

  func registerAllDependency() {
    assembler.apply(assemblies: [
      RepositoryAssembly(),
      UseCaseAssembly()
    ] + [
      BaseAssembly(),
      ApiAssembly(),
      PrivilegeAssembly(),
      RegisterAssembly(),
      ResetPasswordAssembly(),
      NotificationAssembly(),
      PromotionAssembly(),
      NumberGameAssembly(),
      ArcadeAssembly(),
      CasinoAssembly(),
      SlotAssembly(),
      P2pAssembly(),
      WithdrawalAssembly(),
      DepositAssembly(),
      BankAssembly(),
      CustomerServiceAssembly(),
      PlayerAssembly(),
      TransactionAssembly()
    ])
 
    registerFakeNetworkInfra()
    registerNavigator()
  }
  
  // MARK: - Setup Network Infra
  
  func setupNetworkInfra() async {
    let ktoURLManager = KtoURLManager()
    await ktoURLManager.checkHosts()
    
    let cookieManager = CookieManager(
      allHosts: Configuration.hostName.values.flatMap { $0 },
      currentURL: ktoURLManager.portalURL,
      currentDomain: ktoURLManager.currentDomain)

    registerKtoURLManager(ktoURLManager)
    registerCookieManager(cookieManager)

    registerHttpClient(
      cookieManager: cookieManager,
      portalURL: ktoURLManager.portalURL,
      versionUpdateURL: ktoURLManager.versionUpdateURL)
    
    networkReadyRelay.accept(true)
  }
  
  private func registerKtoURLManager(_ ktoURLManager: KtoURLManager) {
    container.register(KtoURLManager.self) { _ in ktoURLManager }
      .inObjectScope(.container)
  }
  
  private func registerCookieManager(_ cookieManager: CookieManager) {
    container.register(CookieManager.self) { _ in cookieManager }
      .inObjectScope(.container)
  }
  
  // MARK: - HttpClient
  
  private func registerFakeNetworkInfra() {
    let fakeURL = URL(string: "https://")!
    
    container
      .register(CookieManager.self) { _ in CookieManager(allHosts: [], currentURL: fakeURL, currentDomain: "") }
      .inObjectScope(.container)
    
    lazy var fakeHttpClient = HttpClient(
      container ~> LocalStorageRepository.self,
      container ~> CookieManager.self,
      currentURL: fakeURL,
      locale: container ~> SupportLocale.self)
    
    container.register(HttpClient.self) { _ in fakeHttpClient }
    container.register(HttpClient.self, name: "update") { _ in fakeHttpClient }
  }
  
  func registerHttpClient(cookieManager: CookieManager, portalURL: URL, versionUpdateURL: URL) {
    container.register(HttpClient.self) {
      HttpClient(
        $0 ~> LocalStorageRepository.self,
        cookieManager,
        currentURL: portalURL,
        locale: $0 ~> SupportLocale.self)
    }
    .inObjectScope(.locale)

    container.register(HttpClient.self, name: "update") {
      HttpClient(
        $0 ~> LocalStorageRepository.self,
        cookieManager,
        currentURL: versionUpdateURL,
        locale: $0 ~> SupportLocale.self)
    }
    .inObjectScope(.locale)
  }

  // MARK: - Navigator
  
  func registerNavigator() {
    container.autoregister(DepositNavigator.self, initializer: DepositNavigatorImpl.init)
  }
}
