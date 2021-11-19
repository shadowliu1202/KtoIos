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
    
    private func convertLocalDateTime(format1: String = "", format2: String = "") -> Date?{
        return convertDateTime(format: format1) ?? convertDateTime(format: format2)
    }
    
    func convertDateTime(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ", timeZone: String? = "UTC") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
    
    func convertOffsetDateTime(format1: String = "", format2: String = "") -> Date?{
        return convertOffsetDateTime(format: format1) ?? convertOffsetDateTime(format: format2)
    }
    
    func convertOffsetDateTime(format: String = "") -> Date?{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
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
    
    func currencyAmountToDeciemal() -> Decimal? {
        return Decimal(string: self.replacingOccurrences(of: ",", with: ""))
    }
    
    func doubleValue() -> Double {
        return (self as NSString).doubleValue
    }
    
    func toLocalDate(format: String = "yyyy-MM-dd") -> Kotlinx_datetimeLocalDate {
        var createDate = Date()
        if let date = self.convertLocalDateTime(format1: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ", format2: "yyyy-MM-dd'T'HH:mm:ssZ") {
            createDate = date
        } else if let d = self.convertDateTime(format: "yyyy/MM/dd") {
            createDate = d
        } else {
            fatalError("toLocalDateTime with worrng format, Date = \(self)")
        }
        return Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth())
    }
    
    func toLocalDateTime() -> Kotlinx_datetimeLocalDateTime {
        var createDate = Date()
        if let date = self.convertLocalDateTime(format1: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ", format2: "yyyy-MM-dd'T'HH:mm:ssZ") {
            createDate = date
        } else {
            fatalError("toLocalDateTime with worrng format, Date = \(self)")
        }
        return Kotlinx_datetimeLocalDateTime.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth(), hour: createDate.getHour(), minute: createDate.getMinute(), second: createDate.getSecond(), nanosecond: createDate.getNanosecond())
    }

    func toOffsetDateTime() -> OffsetDateTime {
        var createDate = Date()
        if let date = self.convertOffsetDateTime(format1: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ", format2: "yyyy-MM-dd'T'HH:mm:ssZ") {
            createDate = date
        } else {
            fatalError("toOffsetDateTime with worrng format, Date = \(self)")
        }
        let createLocalDateTime = Kotlinx_datetimeLocalDateTime(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth(), hour: createDate.getHour(), minute: createDate.getMinute(), second: createDate.getSecond(), nanosecond: createDate.getNanosecond())
        let offsetDateTime = OffsetDateTime.Companion.init().create(localDateTime: createLocalDateTime, zoneId: TimeZone.current.identifier)
        return offsetDateTime
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
}

extension String {
    func removeHtmlTag() -> String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
