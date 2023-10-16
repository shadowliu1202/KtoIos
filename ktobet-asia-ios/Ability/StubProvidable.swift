import Foundation
import sharedbu
import SwiftUI

protocol StubProvidable {
  func stubInstant(_ date: Date) -> Instant
  
  func stubFiatCNY(_ amount: String) -> CurrencyUnit
}

extension StubProvidable {
  func stubInstant(_ date: Date = .init()) -> Instant {
    Instant.companion.fromEpochSeconds(epochSeconds: Int64(date.timeIntervalSince1970), nanosecondAdjustment: 0)
  }
  
  func stubFiatCNY(_ amount: String) -> CurrencyUnit {
    FiatFactory.shared.create(supportLocale: .China(), amount_: amount == "" ? "0" : amount)
  }
}
