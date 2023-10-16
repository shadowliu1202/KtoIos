import sharedbu
import SwiftUI

enum KTOFontWeight: String {
  case regular
  case medium
  case semibold

  func fontString(_ playerLocale: SupportLocale) -> String {
    switch self {
    case .regular:
      switch playerLocale {
      case is SupportLocale.Vietnam:
        return "HelveticaNeue-Light"
      case is SupportLocale.China:
        return "PingFangSC-Regular"
      default:
        return "PingFangSC-Regular"
      }
    case .medium:
      switch playerLocale {
      case is SupportLocale.Vietnam:
        return "HelveticaNeue-Medium"
      case is SupportLocale.China:
        return "PingFangSC-Medium"
      default:
        return "PingFangSC-Medium"
      }
    case .semibold:
      switch playerLocale {
      case is SupportLocale.Vietnam:
        return "HelveticaNeue-Bold"
      case is SupportLocale.China:
        return "PingFangSC-Semibold"
      default:
        return "PingFangSC-Semibold"
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
}
