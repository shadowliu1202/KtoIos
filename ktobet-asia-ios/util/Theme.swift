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
    
    func getSegmentTitleName(by playerLocale: SupportLocale) -> [String] {
        let dateSegmentTitle = [Localize.string("common_last7day"), Localize.string("common_select_day"), Localize.string("common_select_month")]
        switch playerLocale {
        case is SupportLocale.Vietnam:
            return insertNewLineBeforeLastWord(dateSegmentTitle)
        case is SupportLocale.China, is SupportLocale.Unknown:
            fallthrough
        default:
            return dateSegmentTitle
        }
    }
    
    private func insertNewLineBeforeLastWord(_ segmentTitle: [String]) -> [String] {
        var newSegmentTitle: [String] = []
        for title in segmentTitle {
            guard let spaceIndex = title.lastIndex(of: " ") else {
                newSegmentTitle.append(title)
                continue
            }
            
            let spaceIndexRange = title.rangeOfComposedCharacterSequence(at: spaceIndex)
            let newTitle = title.replacingCharacters(in: spaceIndexRange, with: "\n")
            newSegmentTitle.append(newTitle)
        }
        
        return newSegmentTitle
    }
}
