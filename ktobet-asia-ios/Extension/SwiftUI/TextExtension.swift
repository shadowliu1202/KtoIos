import sharedbu
import SwiftUI

enum KTOFontWeight: String {
  case regular
  case medium
  case semibold

  func fontString(_ playerLocale: SupportLocale) -> String {
    switch self {
    case .regular:
      switch onEnum(of: playerLocale) {
      case .china:
        return "PingFangSC-Regular"
      case .vietnam:
        return "HelveticaNeue-Light"
      }
    case .medium:
      switch onEnum(of: playerLocale) {
      case .china:
        return "PingFangSC-Medium"
      case .vietnam:
        return "HelveticaNeue-Medium"
      }
    case .semibold:
      switch onEnum(of: playerLocale) {
      case .china:
        return "PingFangSC-Semibold"
      case .vietnam:
        return "HelveticaNeue-Bold"
      }
    }
  }
}

extension Text {
  init(key: String) {
    self.init(Localize.string(key))
  }

  init(key: String, _ parameters: String...) {
    self.init(Localize.string(key, parameters))
  }

  // FIXME: workaround display vn localize string in preview
  init(key: String, _ parameters: [String], cultureCode: String) {
    self.init(Localize.string(key, parameters, cultureCode))
  }
  
  func addBold(_ isActive: Bool) -> Text {
    isActive ? self.bold() : self
  }
  
  func addItalic(_ isActive: Bool) -> Text {
    isActive ? self.italic() : self
  }
}
