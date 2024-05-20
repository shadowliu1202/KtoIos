import CoreGraphics
import Foundation
import sharedbu
import UIKit

final class Theme {
    static let shared = Theme()

    private init() { }

    func getDatePickerTitleLabel(by playerLocale: SupportLocale, _ koyomi: Koyomi) -> String {
        switch onEnum(of: playerLocale) {
        case .china:
            return koyomi.currentDateString() + Localize.string("common_month")
        case .vietnam:
            return Localize.string("common_month") + " " + koyomi.currentDateString(withFormat: "M") + "/" + koyomi
                .currentDateString(withFormat: "yyyy")
        }
    }

    func getDateSegmentTitleFontSize(by playerLocale: SupportLocale) -> CGFloat {
        switch onEnum(of: playerLocale) {
        case .china:
            return 14
        case .vietnam:
            return 12
        }
    }

    func getSegmentTitleName(by playerLocale: SupportLocale) -> [String] {
        let dateSegmentTitle = [
            Localize.string("common_last7day"),
            Localize.string("common_select_day"),
            Localize.string("common_select_month")
        ]
        switch onEnum(of: playerLocale) {
        case .china:
            return dateSegmentTitle
        case .vietnam:
            return insertNewLineBeforeLastWord(dateSegmentTitle)
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

    func getUIImage(name: String, by playerLocale: SupportLocale) -> UIImage {
        switch onEnum(of: playerLocale) {
        case .china:
            return UIImage(named: name)!
        case .vietnam:
            return UIImage(named: "\(name)-VN")!
        }
    }

    func getMonthCollectionViewCellTitle(_ month: Int, by playerLocale: SupportLocale) -> String {
        switch onEnum(of: playerLocale) {
        case .china:
            return "\(month)\(Localize.string("common_month"))"
        case .vietnam:
            return "\(month)"
        }
    }

    func getRemitterBankCardHeight(by playerLocale: SupportLocale) -> CGFloat {
        switch onEnum(of: playerLocale) {
        case .china:
            return 60
        case .vietnam:
            return 75
        }
    }

    func getDefaultProductTextPadding(by playerLocale: SupportLocale) -> CGFloat {
        switch onEnum(of: playerLocale) {
        case .china:
            return 24
        case .vietnam:
            return 12
        }
    }

    func changeEntireAPPFont(by playerLocale: SupportLocale) {
        switch onEnum(of: playerLocale) {
        case .china:
            UILabel.appearance().substituteFontFamilyName = "PingFangSC"
            UITextView.appearance().substituteFontFamilyName = "PingFangSC"
            UITextField.appearance().substituteFontFamilyName = "PingFangSC"

            let barAppearance = UINavigationBarAppearance()
            barAppearance.configureWithTransparentBackground()
            barAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.greyScaleWhite,
                .font: UIFont(name: "PingFangSC-Semibold", size: 16)!
            ]
            barAppearance.backgroundColor = UIColor.greyScaleDefault.withAlphaComponent(0.9)
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
            UINavigationBar.appearance().standardAppearance = barAppearance
        case .vietnam:
            UILabel.appearance().substituteFontFamilyName = "HelveticaNeue"
            UITextView.appearance().substituteFontFamilyName = "HelveticaNeue"
            UITextField.appearance().substituteFontFamilyName = "HelveticaNeue"

            let barAppearance = UINavigationBarAppearance()
            barAppearance.configureWithTransparentBackground()
            barAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.greyScaleWhite,
                .font: UIFont(name: "HelveticaNeue-Bold", size: 16)!
            ]
            barAppearance.backgroundColor = UIColor.greyScaleDefault.withAlphaComponent(0.9)
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
            UINavigationBar.appearance().standardAppearance = barAppearance
        }
    }

    func getNavigationTitleFont(by playerLocale: SupportLocale) -> UIFont {
        switch onEnum(of: playerLocale) {
        case .china:
            return UIFont(name: "PingFangSC-Semibold", size: 16)!
        case .vietnam:
            return UIFont(name: "HelveticaNeue-Bold", size: 16)!
        }
    }

    func getTextFieldCellMaxLength(by playerLocale: SupportLocale) -> Int {
        switch onEnum(of: playerLocale) {
        case .china:
            return 100
        case .vietnam:
            return 300
        }
    }
  
    @available(*, deprecated, message: "Use extension function, not singleton function.")
    func getBetTimeWeekdayFormat(by playerLocale: SupportLocale) -> DateFormatter {
        let dateFormatter = DateFormatter()
        switch onEnum(of: playerLocale) {
        case .china:
            dateFormatter.locale = Locale(identifier: "zh_Hans_CN")
            dateFormatter.dateFormat = "yyyy/MM/dd (EEEEE) HH:mm:ss"
        case .vietnam:
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm:ss"
        }
        return dateFormatter
    }

    func parse(_ transactionStatus: TransactionStatus) -> UIColor {
        if transactionStatus == .floating {
            return UIColor.alert
        }
        else {
            return UIColor.textPrimary
        }
    }

    func parse(bonusReceivingStatus: BonusReceivingStatus) -> UIColor {
        switch bonusReceivingStatus {
        case .inProgress:
            return UIColor.alert
        case .noTurnOver:
            return UIColor.statusSuccess
        case .completed:
            return UIColor.statusSuccess
        case .canceled:
            return UIColor.textPrimary
        }
    }

    func configNavigationBar(
        _ navigationController: UINavigationController?,
        backgroundColor color: UIColor)
    {
        let barAppearance = UINavigationBarAppearance()

        barAppearance.configureWithTransparentBackground()
        barAppearance.backgroundColor = color
        barAppearance.titleTextAttributes = [.foregroundColor: UIColor.greyScaleWhite]

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.standardAppearance = barAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
    }
}
