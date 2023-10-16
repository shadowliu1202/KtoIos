import sharedbu
import SwiftUI

private struct supportLocale: EnvironmentKey {
  static let defaultValue: SupportLocale = .China()
}

extension EnvironmentValues {
  var playerLocale: SupportLocale {
    get { self[supportLocale.self] }
    set { self[supportLocale.self] = newValue }
  }
}
