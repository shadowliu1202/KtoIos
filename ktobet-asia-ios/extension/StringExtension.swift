import Foundation
import UIKit
import SharedBu

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
    
    func isValidRegex(format: RegexFormat) -> Bool {
        let test = format.predicate

        switch format {
        case .email:
            return test.evaluate(with: self.lowercased())
        default:
            return test.evaluate(with: self)
        }
    }
    
    //Check string contain Zhuyin
    func isContainsPhoneticCharacters() -> Bool {
        for scalar in self.unicodeScalars {
            if (scalar.value >= 12549 && scalar.value <= 12582) || (scalar.value == 12584 || scalar.value == 12585 || scalar.value == 19968) {
                return true
            }
        }
        return false
    }
    
    func currencyAmountToDouble() -> Double? {
        return Double(self.replacingOccurrences(of: ",", with: ""))
    }
    
    func currencyAmountToDecimal() -> Decimal? {
        return Decimal(string: self.replacingOccurrences(of: ",", with: ""))
    }
    
    func doubleValue() -> Double {
        return (self as NSString).doubleValue
    }
}

//MARK: String to DateTime
extension String {
    var playerTimeZone: TimeZone {
        DI.resolve(PlayerConfiguration.self)!.localeTimeZone()
    }

    func toOffsetDateTime() -> OffsetDateTime {
        let offsetDate = getOffsetDate()
        let createLocalDateTime = Kotlinx_datetimeLocalDateTime(year: offsetDate.getYear(), monthNumber: offsetDate.getMonth(), dayOfMonth: offsetDate.getDayOfMonth(), hour: offsetDate.getHour(), minute: offsetDate.getMinute(), second: offsetDate.getSecond(), nanosecond: offsetDate.getNanosecond())
        return OffsetDateTime.Companion.init().create(localDateTime: createLocalDateTime, zoneId: TimeZone.current.identifier)
    }

    func toLocalDateTime() -> Kotlinx_datetimeLocalDateTime {
        let offsetDate = getOffsetDate()
        return Kotlinx_datetimeLocalDateTime.init(year: offsetDate.getYear(), monthNumber: offsetDate.getMonth(), dayOfMonth: offsetDate.getDayOfMonth(), hour: offsetDate.getHour(), minute: offsetDate.getMinute(), second: offsetDate.getSecond(), nanosecond: offsetDate.getNanosecond())
    }

    func toLocalDate() -> Kotlinx_datetimeLocalDate {
        let offsetDate = getOffsetDate()
        return Kotlinx_datetimeLocalDate(year: offsetDate.getYear(), monthNumber: offsetDate.getMonth(), dayOfMonth: offsetDate.getDayOfMonth())
    }

    func toDate(format: String, timeZone: TimeZone) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone
        return dateFormatter.date(from: self)
    }

    private func getOffsetDate() -> Date {
        let dateFormatterWithFractionalSeconds = ISO8601DateFormatter()
        let dateFormatterwithFullDate = ISO8601DateFormatter()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatterwithFullDate.formatOptions = [.withFullDate]
        dateFormatterWithFractionalSeconds.formatOptions = [.withDashSeparatorInDate, .withInternetDateTime, .withFractionalSeconds]
        var date = Date()
        if let createDate = dateFormatterWithFractionalSeconds.date(from: self) {
            date = createDate
        } else if let createDate = dateFormatter.date(from: self) {
            date = createDate
        } else if let createDate = dateFormatterwithFullDate.date(from: self) {
            date = createDate
        }

        let offsetTime = TimeInterval(playerTimeZone.secondsFromGMT())
        date.addTimeInterval(offsetTime)
        return date
    }
}

enum RegexFormat: String {
    case email          = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    case branchName     = #"[\u4e00-\u9fa5\uff00-\uffffa-zA-Z]{1,31}"#
    case cryptoAddress   = "^[a-zA-Z0-9_-]*$"
    case numbers        = "^[0-9]+$"
    
    var predicate: NSPredicate {
        let regex = self.rawValue
        return NSPredicate(format: "SELF MATCHES %@", regex)
    }
}

extension Optional where Wrapped == String {
    func isNullOrEmpty() -> Bool {
        guard let `self` = self else {
            return true
        }
        return self.isEmpty
    }
    
    func toShareOffsetDateTime() -> OffsetDateTime {
        guard let `self` = self else {
            return OffsetDateTime.companion.NotDefine
        }
        return self.toOffsetDateTime()
    }
}

extension String {
    func removeHtmlTag() -> String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

extension String {
    func toAccountCurrency() -> AccountCurrency {
        return FiatFactory.shared.create(supportLocale: LocalStorageRepository().getSupportLocal(), amount_: self.replacingOccurrences(of: ",", with: ""))
    }
    
    func toCryptoCurrency(cryptoCurrencyCode: Int?) -> CryptoCurrency {
        guard let cryptoCurrencyCode = cryptoCurrencyCode else { return CryptoFactory.shared.unknown(amount: "0.0") }
        for index in 0..<SupportCryptoType.values().size {
            if (SupportCryptoType.values().get(index: index))!.id__ == cryptoCurrencyCode {
                return toCryptoCurrency(supportCryptoType: SupportCryptoType.values().get(index: index)!)
            }
        }
        return CryptoFactory.shared.unknown(amount: self)
    }
    
    func toCryptoCurrency(supportCryptoType: SupportCryptoType) -> CryptoCurrency {
        return CryptoFactory.shared.create(supportCryptoType: supportCryptoType, amount_: self)
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        do {
            let style = "<style>body { font-size:\(15)px; }</style>"
            guard let data = (self + style).data(using: .utf8) else { return nil }
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension String {
    var halfWidth: String {
        transformFullWidthToHalfWidth()
    }
    
    private func transformFullWidthToHalfWidth() -> String {
        let string = NSMutableString(string: self) as CFMutableString
        CFStringTransform(string, nil, kCFStringTransformFullwidthHalfwidth, false)
        return string as String
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
}

extension String {
    func replacingLastOccurrenceOfString(_ searchString: String, with replacementString: String, caseInsensitive: Bool = true) -> String {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        } else {
            options = [.backwards]
        }
        
        if let range = self.range(of: searchString,
                                  options: options,
                                  range: nil,
                                  locale: nil) {
            
            return self.replacingCharacters(in: range, with: replacementString)
        }
        return self
    }
}

extension String {
    var isNotEmpty: Bool { !self.isEmpty }
}
