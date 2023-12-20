import Foundation
import sharedbu

extension PlayerConfiguration {
  static let defaultLocale = SupportLocale.Vietnam()
  
  func localeTimeZone() -> Foundation.TimeZone {
    let kotlinTimeZone = self.timezone()
    return Foundation.TimeZone(identifier: kotlinTimeZone.description()) ?? Foundation.TimeZone.current
  }
}
