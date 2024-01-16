import RxCocoa
import RxSwift
import sharedbu

class ConfigurationViewModel {
  private let localStorageRepo: LocalStorageRepository
  private let appService: DefaultProductAppService

  init(_ localStorageRepo: LocalStorageRepository, _ appService: DefaultProductAppService) {
    self.localStorageRepo = localStorageRepo
    self.appService = appService
  }

  func fetchDefaultProduct() -> Single<DefaultProductType?> {
    Single.from(appService.getDefaultProduct())
      .map { $0.data }
  }

  func saveDefaultProduct(productType: DefaultProductType) -> Completable {
    Completable.from(appService.setDefaultProduct(type: productType))
  }

  func refreshPlayerInfoCache(_ productType: ProductType) {
    localStorageRepo.updatePlayerInfoCache(productType: productType)
  }
}
