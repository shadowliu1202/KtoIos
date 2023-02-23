import RxCocoa
import RxSwift
import SharedBu

class ConfigurationViewModel {
  private let configurationUseCase: ConfigurationUseCase
  private let localStorageRepo: LocalStorageRepository

  init(_ configurationUseCase: ConfigurationUseCase, _ localStorageRepo: LocalStorageRepository) {
    self.configurationUseCase = configurationUseCase
    self.localStorageRepo = localStorageRepo
  }

  func fetchDefaultProduct() -> Single<ProductType> {
    configurationUseCase.defaultProduct()
  }

  func saveDefaultProduct(productType: ProductType) -> Completable {
    configurationUseCase.saveDefaultProduct(productType)
  }

  func refreshPlayerInfoCache(_ productType: ProductType) {
    guard let playerInfoCache = localStorageRepo.getPlayerInfo() else {
      fatalError("Should not happened.")
    }

    let newPlayerInfoCache = PlayerInfoCache(
      account: playerInfoCache.account,
      ID: playerInfoCache.ID,
      locale: playerInfoCache.locale,
      VIPLevel: playerInfoCache.VIPLevel,
      defaultProduct: ProductType.convert(productType))

    localStorageRepo.setPlayerInfo(newPlayerInfoCache)
  }
}
