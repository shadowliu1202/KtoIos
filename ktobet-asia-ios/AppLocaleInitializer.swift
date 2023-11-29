import Foundation
import sharedbu

class AppLocaleInitializer: LocalStorable {
  private let localStorageRepository: LocalStorageRepository
  private let languageCode: String
  
  init(
    languageCode: String = Locale.current.languageCode ?? "",
    _ localStorageRepository: LocalStorageRepository)
  {
    self.languageCode = languageCode
    self.localStorageRepository = localStorageRepository
  }
  
  func initLocale() {
    let cultureCode = get(key: .cultureCode) ?? initCultureCode()
    Theme.shared.changeEntireAPPFont(by: localStorageRepository.getSupportLocale())
  }
  
  private func initCultureCode() -> String {
    let localeCultureCode = systemLocaleToCultureCode()
    set(value: localeCultureCode, key: .cultureCode)
    
    return localeCultureCode
  }

  private func systemLocaleToCultureCode() -> String {
    switch languageCode {
    case "vi":
      fallthrough
    default:
      return SupportLocale.Vietnam.shared.cultureCode()
    }
  }
}
