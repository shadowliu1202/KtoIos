import Foundation
import UIKit

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
    
    func convertDateTime() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSZ"
        let date = dateFormatter.date(from: self)
        return date
    }
    
    func convertDateTIme(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = .current
        let date = dateFormatter.date(from: self)
        return date
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
}

enum RegexFormat: String {
    case email          = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    case branchName     = #"[\u4e00-\u9fa5\uff00-\uffffa-zA-Z]{1,31}"#
    
    var predicate: NSPredicate {
        let regex = self.rawValue
        return NSPredicate(format: "SELF MATCHES %@", regex)
    }
}
