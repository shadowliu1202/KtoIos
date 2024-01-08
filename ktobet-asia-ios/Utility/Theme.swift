import CoreGraphics
import Foundation
import sharedbu
import UIKit

final class Theme {
  static let shared = Theme()

  private init() { }

  func getDatePickerTitleLabel(by playerLocale: SupportLocale, _ koyomi: Koyomi) -> String {
    switch playerLocale {
    case is SupportLocale.China:
      return koyomi.currentDateString() + Localize.string("common_month")
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return Localize.string("common_month") + " " + koyomi.currentDateString(withFormat: "M") + "/" + koyomi
        .currentDateString(withFormat: "yyyy")
    }
  }

  func getDateSegmentTitleFontSize(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.China:
      return 14
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return 12
    }
  }

  func getSegmentTitleName(by playerLocale: SupportLocale) -> [String] {
    let dateSegmentTitle = [
      Localize.string("common_last7day"),
      Localize.string("common_select_day"),
      Localize.string("common_select_month")
    ]
    switch playerLocale {
    case is SupportLocale.China:
      return dateSegmentTitle
    case is SupportLocale.Vietnam:
      fallthrough
    default:
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
    switch playerLocale {
    case is SupportLocale.China:
      return UIImage(named: name)!
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return UIImage(named: "\(name)-VN")!
    }
  }

  func getMonthCollectionViewCellTitle(_ month: Int, by playerLocale: SupportLocale) -> String {
    switch playerLocale {
    case is SupportLocale.China:
      return "\(month)\(Localize.string("common_month"))"
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return "\(month)"
    }
  }

  func getRemitterBankCardHeight(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.China:
      return 60
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return 75
    }
  }

  func getDefaultProductTextPadding(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.China:
      return 24
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return 12
    }
  }

  func changeEntireAPPFont(by playerLocale: SupportLocale) {
    switch playerLocale {
    case is SupportLocale.China:
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
      
    case is SupportLocale.Vietnam:
      fallthrough
      
    default:
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
    switch playerLocale {
    case is SupportLocale.China:
      return UIFont(name: "PingFangSC-Semibold", size: 16)!
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return UIFont(name: "HelveticaNeue-Bold", size: 16)!
    }
  }

  func getTextFieldCellMaxLength(by playerLocale: SupportLocale) -> Int {
    switch playerLocale {
    case is SupportLocale.China:
      return 100
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      return 300
    }
  }
  
  @available(*, deprecated, message: "Use extension function, not singleton function.")
  func getBetTimeWeekdayFormat(by playerLocale: SupportLocale) -> DateFormatter {
    let dateFormatter = DateFormatter()
    switch playerLocale {
    case is SupportLocale.China:
      dateFormatter.locale = Locale(identifier: "zh_Hans_CN")
      dateFormatter.dateFormat = "yyyy/MM/dd (EEEEE) HH:mm:ss"
    case is SupportLocale.Vietnam:
      fallthrough
    default:
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      dateFormatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm:ss"
    }
    return dateFormatter
  }

  func parse(_ transactionStatus: TransactionStatus) -> UIColor {
    switch transactionStatus {
    case .floating:
      return UIColor.alert
    default:
      return UIColor.textPrimary
    }
  }

  func parse(bonusReceivingStatus: BonusReceivingStatus) -> UIColor {
    switch bonusReceivingStatus {
    case .inprogress:
      return UIColor.alert
    case .noturnover:
      return UIColor.statusSuccess
    case .completed:
      return UIColor.statusSuccess
    case .canceled:
      return UIColor.textPrimary
    default:
      return UIColor.clear
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
