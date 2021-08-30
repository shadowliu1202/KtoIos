import Foundation

extension Double {
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
    func currencyFormatWithoutSymbol(precision: Int = 0, maximumFractionDigits: Int = 2) -> String {
        let numberFormatter = Formatter.withSeparator
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.minimumFractionDigits = precision
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        numberFormatter.roundingMode = .down
        return numberFormatter.string(for: self) ?? ""
    }
}
