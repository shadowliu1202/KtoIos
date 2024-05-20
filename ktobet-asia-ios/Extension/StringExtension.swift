import Foundation
import sharedbu
import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil)

        return ceil(boundingBox.width)
    }

    func isValidRegex(format: RegexFormat) -> Bool {
        let test = format.predicate

        switch format {
        case .email:
            return test.evaluate(with: self.lowercased())
        case .branchName,
             .cryptoAddress,
             .numbers:
            return test.evaluate(with: self)
        }
    }

    func currencyAmountToDouble() -> Double? {
        Double(self.replacingOccurrences(of: ",", with: ""))
    }

    func currencyAmountToDecimal() -> Decimal? {
        Decimal(string: self.replacingOccurrences(of: ",", with: ""))
    }

    func doubleValue() -> Double {
        (self as NSString).doubleValue
    }

    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
}

// MARK: String to DateTime
extension String {
    @available(*, deprecated, message: "Should not use DI in extension.")
    private static func getPlayerTimeZone() -> Foundation.TimeZone {
        Injectable.resolve(PlayerConfiguration.self)!.localeTimeZone()
    }

    func toOffsetDateTime(timeZone: Foundation.TimeZone = String.getPlayerTimeZone()) throws -> OffsetDateTime {
        let localDateTime = try toKotlinLocalDateTime(timeZone: timeZone)
        return OffsetDateTime.Companion().create(localDateTime: localDateTime, zoneId: timeZone.identifier)
    }

    func toOffsetDateTimeWithAccountTimeZone(
        timeZone: Foundation.TimeZone = String
            .getPlayerTimeZone()) throws
        -> OffsetDateTime
    {
        let localDateTime = try toLocalDateTimeWithAccountTimeZone()
        return OffsetDateTime.Companion().create(localDateTime: localDateTime, zoneId: timeZone.identifier)
    }

    func toKotlinLocalDateTime(timeZone: Foundation.TimeZone = String.getPlayerTimeZone()) throws -> sharedbu.LocalDateTime {
        var offsetDate = try DateUtils.parseOffsetDate(string: self)
        let offsetTime = TimeInterval(timeZone.secondsFromGMT())
        offsetDate.addTimeInterval(offsetTime)
        let localDate = offsetDate
        return sharedbu.LocalDateTime(
            year: localDate.getYear(),
            monthNumber: localDate.getMonth(),
            dayOfMonth: localDate.getDayOfMonth(),
            hour: localDate.getHour(),
            minute: localDate.getMinute(),
            second: localDate.getSecond(),
            nanosecond: localDate.getNanosecond())
    }

    func toLocalDateTimeWithAccountTimeZone() throws -> sharedbu.LocalDateTime {
        let localDate = try DateUtils.parseLocalDate(string: self)
        return sharedbu.LocalDateTime(
            year: localDate.getYear(),
            monthNumber: localDate.getMonth(),
            dayOfMonth: localDate.getDayOfMonth(),
            hour: localDate.getHour(),
            minute: localDate.getMinute(),
            second: localDate.getSecond(),
            nanosecond: localDate.getNanosecond())
    }

    func toKotlinLocalDate(timeZone: Foundation.TimeZone = String.getPlayerTimeZone()) throws -> sharedbu.LocalDate {
        var offsetDate = try DateUtils.parseOffsetDate(string: self)
        let offsetTime = TimeInterval(timeZone.secondsFromGMT())
        offsetDate.addTimeInterval(offsetTime)
        let localDate = offsetDate
        return sharedbu.LocalDate(
            year: localDate.getYear(),
            monthNumber: localDate.getMonth(),
            dayOfMonth: localDate.getDayOfMonth())
    }

    func toLocalDateWithAccountTimeZone() throws -> sharedbu.LocalDate {
        let localDate = try DateUtils.parseLocalDate(string: self)
        return sharedbu.LocalDate(
            year: localDate.getYear(),
            monthNumber: localDate.getMonth(),
            dayOfMonth: localDate.getDayOfMonth())
    }

    func toDate(format: String, timeZone: Foundation.TimeZone) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = timeZone
        return dateFormatter.date(from: self)
    }

    func getOffsetDate() -> Date {
        let dateFormatterWithFractionalSeconds = ISO8601DateFormatter()
        let dateFormatterwithFullDate = ISO8601DateFormatter()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatterwithFullDate.formatOptions = [.withFullDate]
        dateFormatterWithFractionalSeconds.formatOptions = [
            .withDashSeparatorInDate,
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        var date = Date()
        if let createDate = dateFormatterWithFractionalSeconds.date(from: self) {
            date = createDate
        }
        else if let createDate = dateFormatter.date(from: self) {
            date = createDate
        }
        else if let createDate = dateFormatterwithFullDate.date(from: self) {
            date = createDate
        }

        return date
    }
}

enum RegexFormat: String {
    case email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    case branchName = #"[\u4e00-\u9fa5\uff00-\uffffa-zA-Z]{1,31}"#
    case cryptoAddress = "^[a-zA-Z0-9_-]*$"
    case numbers = "^[0-9]+$"

    var predicate: NSPredicate {
        let regex = self.rawValue
        return NSPredicate(format: "SELF MATCHES %@", regex)
    }
}

extension String? {
    func isNullOrEmpty() -> Bool {
        guard let self else {
            return true
        }
        return self.isEmpty
    }

    func toShareOffsetDateTime() throws -> OffsetDateTime {
        guard let self else {
            return OffsetDateTime.companion.NotDefine
        }
        return try self.toOffsetDateTime()
    }
}

extension String {
    func removeHtmlTag() -> String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

extension String {
    func toAccountCurrency() -> AccountCurrency {
        let playerConfiguration = Injectable.resolve(PlayerConfiguration.self)!

        return FiatFactory.shared.create(
            supportLocale: playerConfiguration.supportLocale,
            amount: self.replacingOccurrences(of: ",", with: ""))
    }

    func toCryptoCurrency(cryptoCurrencyCode: Int?) -> CryptoCurrency {
        guard let cryptoCurrencyCode else { return CryptoFactory.shared.unknown(amount: "0.0") }
        for index in 0..<SupportCryptoType.allCases.count {
            if SupportCryptoType.allCases[index].id == cryptoCurrencyCode {
                return toCryptoCurrency(supportCryptoType: SupportCryptoType.allCases[index])
            }
        }
        return CryptoFactory.shared.unknown(amount: self)
    }

    func toCryptoCurrency(supportCryptoType: SupportCryptoType) -> CryptoCurrency {
        CryptoFactory.shared.create(
            supportCryptoType: supportCryptoType,
            amount: self.replacingOccurrences(of: ",", with: ""))
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        do {
            let style = "<style>body { font-size:\(15)px; }</style>"
            guard let data = (self + style).data(using: .utf8) else { return nil }
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
        }
        catch {
            return nil
        }
    }

    var htmlToString: String {
        htmlToAttributedString?.string ?? ""
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
    func index(of string: some StringProtocol, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
}

extension String {
    func replacingLastOccurrenceOfString(
        _ searchString: String,
        with replacementString: String,
        caseInsensitive: Bool = true)
        -> String
    {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        }
        else {
            options = [.backwards]
        }

        if
            let range = self.range(
                of: searchString,
                options: options,
                range: nil,
                locale: nil)
        {
            return self.replacingCharacters(in: range, with: replacementString)
        }
        return self
    }
}

extension String {
    var isNotEmpty: Bool { !self.isEmpty }
}

extension String {
    func replacingRegex(
        matching pattern: String,
        findingOptions: NSRegularExpression.Options = [],
        replacingOptions: NSRegularExpression.MatchingOptions = [],
        with template: String) throws
        -> String
    {
        let regex = try NSRegularExpression(pattern: pattern, options: findingOptions)
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: replacingOptions, range: range, withTemplate: template)
    }

    func removeAccent() -> String {
        Localize.removeAccent(str: self)
    }
}

extension String {
    var attributed: NSMutableAttributedString {
        .init(string: self)
    }

    func ranges(of occurrence: String, skip: Int = 0) -> [Range<String.Index>] {
        var indices = [Int]()
        var position = self.index(startIndex, offsetBy: skip)

        while let range = range(of: occurrence, range: position..<endIndex) {
            let offset = occurrence.distance(from: occurrence.startIndex, to: occurrence.endIndex) - 1
            guard
                let after = index(
                    range.lowerBound,
                    offsetBy: offset,
                    limitedBy: endIndex)
            else { break }

            indices.append(distance(from: startIndex, to: range.lowerBound))
            position = index(after: after)
        }

        let count = occurrence.count
        return indices.map { index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0 + count) }
    }
}

// MARK: - NSMutableAttributedString

extension NSMutableAttributedString {
    @discardableResult
    func textColor(_ color: UIColor) -> NSMutableAttributedString {
        addAttribute(
            .foregroundColor,
            value: color,
            range: .init(location: 0, length: self.length))
        return self
    }

    @discardableResult
    func font(
        weight: KTOFontWeight,
        locale: SupportLocale,
        size: CGFloat)
        -> NSMutableAttributedString
    {
        addAttribute(
            .font,
            value: UIFont(name: weight.fontString(locale), size: size) ?? .systemFont(ofSize: size),
            range: .init(location: 0, length: self.length))
        return self
    }

    @discardableResult
    func highlights(
        weight: KTOFontWeight,
        locale: SupportLocale,
        size: CGFloat,
        color: UIColor,
        subStrings: [String?],
        skip: String = "")
        -> NSMutableAttributedString
    {
        let font = UIFont(name: weight.fontString(locale), size: size) ?? .systemFont(ofSize: size)

        subStrings
            .compactMap { $0 }
            .forEach { string in
                guard self.string.count > skip.count else { return }

                for item in self.string.ranges(of: string, skip: skip.count) {
                    addAttributes(
                        [.font: font, .foregroundColor: color],
                        range: NSRange(item, in: self.string))
                }
            }

        return self
    }
}
