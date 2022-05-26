import Foundation
import SharedBu
import CoreGraphics

final class Theme {
    static let shared = Theme()
    
    private init() {}
    
    func getDatePickerTitleLabel(by playerLocale: SupportLocale, _ koyomi: Koyomi) -> String {
        switch playerLocale {
        case is SupportLocale.Vietnam:
            return Localize.string("common_month") + " " + koyomi.currentDateString(withFormat: "M") + "/" + koyomi.currentDateString(withFormat: "yyyy")
        case is SupportLocale.China, is SupportLocale.Unknown:
            fallthrough
        default:
            return koyomi.currentDateString() + Localize.string("common_month")
        }
    }
    
    func getDateSegmentTitleFontSize(by playerLocale: SupportLocale) -> CGFloat {
        switch playerLocale {
        case is SupportLocale.Vietnam:
            return 12
        case is SupportLocale.China, is SupportLocale.Unknown:
            fallthrough
        default:
            return 14
        }
    }
}
