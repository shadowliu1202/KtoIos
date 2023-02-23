import SharedBu
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
  @ViewBuilder
  func alertStyle() -> some View {
    self
      .localized(weight: .regular, size: 14, color: .whitePure)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 12)
      .padding(.horizontal, 15)
      .backgroundColor(.orangeFF8000)
      .cornerRadius(8)
      .fixedSize(horizontal: false, vertical: true)
  }
}
