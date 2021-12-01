import Foundation
import SharedBu

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
    
    func toAccountCurrency() -> AccountCurrency {
        return FiatFactory.shared.create(supportLocale: LocalStorageRepository().getSupportLocal(), amount_: "\(self)")
    }
    
    func toCryptoCurrency(_ cryptoCurrencyCode: Int) -> CryptoCurrency {
        for idx in 0..<SupportCryptoType.values().size {
            if let supportCryptoType = SupportCryptoType.values().get(index: idx), supportCryptoType.id__ == cryptoCurrencyCode {
                return toCryptoCurrency(supportCryptoType)
            }
        }
        return CryptoFactory.init().unknown(amount: "")
    }
    
    func toCryptoCurrency(_ supportCryptoType: SupportCryptoType) -> CryptoCurrency {
        CryptoFactory.shared.create(supportCryptoType: supportCryptoType, amount_: "\(self)")
    }
}
