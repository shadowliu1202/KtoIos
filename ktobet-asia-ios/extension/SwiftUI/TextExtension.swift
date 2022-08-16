import SwiftUI
import SharedBu

enum KTOFontWeight: String {
    case regular
    case medium
    case semibold
    
    func getSuffix(_ playerLocale: SupportLocale) -> String {
        switch self {
        case .regular:
            switch playerLocale {
            case is SupportLocale.Vietnam:
                return "Light"
            case is SupportLocale.China:
                fallthrough
            default:
                return "Regular"
            }
        case .medium:
            switch playerLocale {
            case is SupportLocale.Vietnam:
                return "Medium"
            case is SupportLocale.China:
                fallthrough
            default:
                return "Medium"
            }
        case .semibold:
            switch playerLocale {
            case is SupportLocale.Vietnam:
                return "Bold"
            case is SupportLocale.China:
                fallthrough
            default:
                return "Semibold"
            }
        }
    }
}

enum KTOTextColor {
    case primaryGray
    case primaryRed
    case white
    case alert

    var value: Color {
        switch self {
        case .primaryGray:
            return .primaryGray
        case .primaryRed:
            return .primaryRed
        case .white:
            return .white
        case .alert:
            return .alert
        }
    }
}

extension Text {
    @ViewBuilder
    func alertStyle() -> some View {
        self
            .customizedFont(fontWeight: .regular, size: 14, color: .white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .backgroundColor(.alert)
            .cornerRadius(8)
            .fixedSize(horizontal: false, vertical: true)
    }
}
