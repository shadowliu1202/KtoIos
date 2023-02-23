import CoreGraphics
import Foundation
import SharedBu
import UIKit

final class Theme {
  static let shared = Theme()

  private init() { }

  func getDatePickerTitleLabel(by playerLocale: SupportLocale, _ koyomi: Koyomi) -> String {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return Localize.string("common_month") + " " + koyomi.currentDateString(withFormat: "M") + "/" + koyomi
        .currentDateString(withFormat: "yyyy")
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return koyomi.currentDateString() + Localize.string("common_month")
    }
  }

  func getDateSegmentTitleFontSize(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return 12
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return 14
    }
  }

  func getSegmentTitleName(by playerLocale: SupportLocale) -> [String] {
    let dateSegmentTitle = [
      Localize.string("common_last7day"),
      Localize.string("common_select_day"),
      Localize.string("common_select_month")
    ]
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return insertNewLineBeforeLastWord(dateSegmentTitle)
    case is SupportLocale.China,
         is SupportLocale.Unknown:
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

  func getUIImage(name: String, by playerLocale: SupportLocale) -> UIImage {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return UIImage(named: "\(name)-VN")!
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return UIImage(named: name)!
    }
  }

  func getMonthCollectionViewCellTitle(_ month: Int, by playerLocale: SupportLocale) -> String {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return "\(month)"
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return "\(month)\(Localize.string("common_month"))"
    }
  }

  func getRemitterBankCardHeight(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return 75
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return 60
    }
  }

  func getDefaultProductTextPadding(by playerLocale: SupportLocale) -> CGFloat {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return 12
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return 24
    }
  }

  func changeEntireAPPFont(by playerLocale: SupportLocale) {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      UILabel.appearance().substituteFontFamilyName = "HelveticaNeue"
      UITextView.appearance().substituteFontFamilyName = "HelveticaNeue"
      UITextField.appearance().substituteFontFamilyName = "HelveticaNeue"

      let barAppearance = UINavigationBarAppearance()
      barAppearance.configureWithTransparentBackground()
      barAppearance.titleTextAttributes = [
        .foregroundColor: UIColor.whitePure,
        .font: UIFont(name: "HelveticaNeue-Bold", size: 16)!
      ]
      barAppearance.backgroundColor = UIColor.black131313.withAlphaComponent(0.9)
      UINavigationBar.appearance().isTranslucent = true
      UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
      UINavigationBar.appearance().standardAppearance = barAppearance

    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      UILabel.appearance().substituteFontFamilyName = "PingFangSC"
      UITextView.appearance().substituteFontFamilyName = "PingFangSC"
      UITextField.appearance().substituteFontFamilyName = "PingFangSC"

      let barAppearance = UINavigationBarAppearance()
      barAppearance.configureWithTransparentBackground()
      barAppearance.titleTextAttributes = [
        .foregroundColor: UIColor.whitePure,
        .font: UIFont(name: "PingFangSC-Semibold", size: 16)!
      ]
      barAppearance.backgroundColor = UIColor.black131313.withAlphaComponent(0.9)
      UINavigationBar.appearance().isTranslucent = true
      UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
      UINavigationBar.appearance().standardAppearance = barAppearance
    }
  }

  func getSignupLanguageViewFont(by playerLocale: SupportLocale) -> [String: UIFont] {
    var fontDictionary: [String: UIFont]
    switch playerLocale {
    case is SupportLocale.Vietnam:
      fontDictionary = [
        "btnNext": UIFont(name: "HelveticaNeue", size: 16)!,
        "btnTerms": UIFont(name: "HelveticaNeue", size: 14)!,
        "labTitle": UIFont(name: "HelveticaNeue-Light", size: 14)!,
        "labDesc": UIFont(name: "HelveticaNeue", size: 24)!,
        "labTermsTip": UIFont(name: "HelveticaNeue-Light", size: 12)!,
        "btnTermsOfService": UIFont(name: "HelveticaNeue-Light", size: 12)!
      ]

      return fontDictionary
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      fontDictionary = [
        "btnNext": UIFont(name: "PingFangSC-Regular", size: 16)!,
        "btnTerms": UIFont(name: "PingFangSC-Regular", size: 14)!,
        "labTitle": UIFont(name: "PingFangSC-Medium", size: 14)!,
        "labDesc": UIFont(name: "PingFangSC-Regular", size: 24)!,
        "labTermsTip": UIFont(name: "PingFangSC-Medium", size: 12)!,
        "btnTermsOfService": UIFont(name: "PingFangSC-Medium", size: 12)!
      ]
      return fontDictionary
    }
  }

  func getNavigationTitleFont(by playerLocale: SupportLocale) -> UIFont {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return UIFont(name: "HelveticaNeue-Bold", size: 16)!
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return UIFont(name: "PingFangSC-Semibold", size: 16)!
    }
  }

  func getTextFieldCellMaxLength(by playerLocale: SupportLocale) -> Int {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      return 300
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return 100
    }
  }

  func getBetTimeWeekdayFormat(by playerLocale: SupportLocale) -> DateFormatter {
    let dateFormatter = DateFormatter()
    switch playerLocale {
    case is SupportLocale.Vietnam:
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      dateFormatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm:ss"
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      dateFormatter.locale = Locale(identifier: "zh_Hans_CN")
      dateFormatter.dateFormat = "yyyy/MM/dd (EEEEE) HH:mm:ss"
    }
    return dateFormatter
  }

  func parse(_ transactionStatus: TransactionStatus) -> UIColor {
    switch transactionStatus {
    case .floating:
      return UIColor.orangeFF8000
    default:
      return UIColor.gray9B9B9B
    }
  }

  func parse(bonusReceivingStatus: BonusReceivingStatus) -> UIColor {
    switch bonusReceivingStatus {
    case .inprogress:
      return UIColor.orangeFF8000
    case .noturnover:
      return UIColor.green6AB336
    case .completed:
      return UIColor.green6AB336
    case .canceled:
      return UIColor.gray9B9B9B
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
    barAppearance.titleTextAttributes = [.foregroundColor: UIColor.whitePure]

    navigationController?.navigationBar.isTranslucent = true
    navigationController?.navigationBar.standardAppearance = barAppearance
    navigationController?.navigationBar.scrollEdgeAppearance = barAppearance
  }
}
