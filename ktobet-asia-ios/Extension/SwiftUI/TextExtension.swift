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
        return "HelveticaNeue-Light"
      }
    case .medium:
      switch playerLocale {
      case is SupportLocale.Vietnam:
        return "HelveticaNeue-Medium"
      case is SupportLocale.China:
        return "PingFangSC-Medium"
      default:
        return "HelveticaNeue-Medium"
      }
    case .semibold:
      switch playerLocale {
      case is SupportLocale.Vietnam:
        return "HelveticaNeue-Bold"
      case is SupportLocale.China:
        return "PingFangSC-Semibold"
      default:
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
    if isActive {
      return self.bold()
    }
    else {
      return self
    }
  }
  
  func addItalic(_ isActive: Bool) -> Text {
    if isActive {
      return self.italic()
    }
    else {
      return self
    }
  }
}
