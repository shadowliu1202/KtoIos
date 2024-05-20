import Foundation
import SwiftUI
import UIKit

class CurrencyType: TextFieldType {
    private let maxAmount: Decimal?

    let regex: CurrencyRegex
    let disablePaste = true

    lazy var keyboardType: UIKeyboardType = regex == .noDecimal ? .numberPad : .decimalPad

    init(
        regex: CurrencyRegex,
        maxAmount: Decimal? = nil)
    {
        self.regex = regex
        self.maxAmount = maxAmount
    }

    func format(_ oldText: String, _ newText: String, _ afterFormat: (String) -> Void) {
        var newText = newText

        guard newText ~= regex.pattern
        else {
            afterFormat(oldText)
            return
        }

        if let maxDigits = regex.maxDigits {
            guard
                !isEndWithDecimalPoint(newText),
                !isAfterDecimalPointInputInProgress(newText, maxDigits: maxDigits)
            else {
                afterFormat(newText)
                return
            }
        }

        checkDeletedThousandsSeparators(oldText, &newText)

        afterFormat(toCurrencyFormat(newText) ?? "")
    }

    private func isEndWithDecimalPoint(_ text: String) -> Bool {
        if text.last == "." {
            return true
        }
        else {
            return false
        }
    }

    private func isAfterDecimalPointInputInProgress(_ text: String, maxDigits: Int) -> Bool {
        let splittedText = text.split(separator: ".")

        guard splittedText.count == 2 else { return false }

        if splittedText[1].count == maxDigits {
            return false
        }
        else {
            return true
        }
    }

    private func checkDeletedThousandsSeparators(_ oldText: String, _ newText: inout String) {
        var oldText = oldText

        if
            let formattedNewText = toCurrencyFormat(newText),
            oldText == formattedNewText,
            oldText.count > newText.count
        {
            var deletedIndex: Int?

            for (index, character) in newText.enumerated() {
                if
                    deletedIndex == nil,
                    character != oldText[oldText.index(oldText.startIndex, offsetBy: index)]
                {
                    deletedIndex = index
                }
            }

            guard let deletedIndex else { return }

            oldText.remove(at: oldText.index(oldText.startIndex, offsetBy: deletedIndex - 1))
            newText = oldText
        }
    }

    private func toCurrencyFormat(_ text: String) -> String? {
        var text = text.replacingOccurrences(of: ",", with: "")

        checkStartWithDecimalPoint(&text)

        guard var amount = Decimal(string: text) else { return nil }

        checkMaxAmountLimit(&amount)

        return amount.currencyFormatWithoutSymbol(maximumFractionDigits: regex.maxDigits ?? 0)
    }

    private func checkStartWithDecimalPoint(_ text: inout String) {
        if text.first == "." {
            text = "0" + text
        }
    }

    private func checkMaxAmountLimit(_ amount: inout Decimal) {
        if let maxAmount, amount > maxAmount {
            amount = maxAmount
        }
    }

    func onEditEnd(_ text: Binding<String>) {
        text.wrappedValue = toCurrencyFormat(text.wrappedValue) ?? text.wrappedValue
    }
}
