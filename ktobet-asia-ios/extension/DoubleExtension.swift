import Foundation

extension Double {
    func currencyFormat(locale: Locale = Locale(identifier: "zh_Hans_CN")) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        if var formattedTipAmount = formatter.string(from: self as NSNumber) {
            let index = formattedTipAmount.index(formattedTipAmount.startIndex, offsetBy: 1)
            formattedTipAmount.insert(" ", at: index)
            return formattedTipAmount
        }
        
        return String(self)
    }
    
    func currencyFormatWithoutSymbol(precision: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = precision
        numberFormatter.maximumFractionDigits = 2
        
        return numberFormatter.string(from: self as NSNumber)!
    }
    
    func currencyFormatWithoutSymbol() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        return numberFormatter.string(from: self as NSNumber)!
    }
    
    func decimalCount() -> Int {
        if self == Double(Int(self)) {
            return 0
        }
        
        let integerString = String(Int(self))
        let doubleString = String(Double(self))
        let decimalCount = doubleString.count - integerString.count - 1
        
        return decimalCount
    }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}

extension Numeric {
    var formattedWithSeparator: String { Formatter.withSeparator.string(for: self) ?? "" }
}
