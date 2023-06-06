import Foundation
import SharedBu

extension PlayerConfiguration {
  func localeTimeZone() -> Foundation.TimeZone {
    let kotlinTimeZone = self.timezone()
    return Foundation.TimeZone(identifier: kotlinTimeZone.description()) ?? Foundation.TimeZone.current
  }
}
