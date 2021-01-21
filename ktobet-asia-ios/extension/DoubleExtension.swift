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
}
