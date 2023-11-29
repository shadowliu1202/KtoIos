import Foundation
import sharedbu

class ForceLocaleLocalStorageRepository: LocalStorageRepositoryImpl {
  private let forceLocale: SupportLocale

  init(forceLocale: SupportLocale, _ playerConfiguration: PlayerConfiguration) {
    self.forceLocale = forceLocale
    super.init(playerConfiguration: playerConfiguration)
  }
  
  override func getCultureCode() -> String {
    forceLocale.cultureCode()
  }
  
  override func getSupportLocale() -> SupportLocale {
    forceLocale
  }
}
