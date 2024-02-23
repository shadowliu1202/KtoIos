import sharedbu
import SwiftUI

// FIXME: workaround display vn localize string in preview
struct LocalizeText: View {
  @Environment(\.playerLocale) var playerLocale: SupportLocale

  private let key: String
  private let parameters: [String]

  init(key: String, _ parameters: String...) {
    self.key = key
    self.parameters = parameters
  }

  var body: some View {
    Text(key: key, parameters, cultureCode: getCultureCode())
  }

  private func getCultureCode() -> String {
    switch onEnum(of: playerLocale) {
    case .vietnam:
      return "vi-vn"
    case .china:
      return "zh-cn"
    }
  }
}
