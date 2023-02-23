import Foundation
import RxSwift
import SharedBu

protocol ConfigurationUseCase {
  func defaultProduct() -> Single<ProductType>
  func saveDefaultProduct(_ productType: ProductType) -> Completable
  func getPlayerInfo() -> Single<Player>
  func locale() -> SupportLocale
  func getOtpRetryCount() -> Int
  func setOtpRetryCount(_ count: Int)
}

class ConfigurationUseCaseImpl: ConfigurationUseCase {
  var playerRepo: PlayerRepository!
  private var localStorageRepository: LocalStorageRepository!

  init(_ playerRepo: PlayerRepository, _ localStorageRepository: LocalStorageRepository) {
    self.playerRepo = playerRepo
    self.localStorageRepository = localStorageRepository
  }

  func defaultProduct() -> Single<ProductType> {
    playerRepo.getDefaultProduct()
  }

  func saveDefaultProduct(_ productType: ProductType) -> Completable {
    playerRepo.saveDefaultProduct(productType)
  }

  func getPlayerInfo() -> Single<Player> {
    playerRepo.loadPlayer()
  }

  func locale() -> SupportLocale {
    localStorageRepository.getSupportLocale()
  }

  func getOtpRetryCount() -> Int {
    localStorageRepository.getRetryCount()
  }

  func setOtpRetryCount(_ count: Int) {
    localStorageRepository.setRetryCount(count)
  }
}
