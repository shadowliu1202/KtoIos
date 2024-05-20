import Foundation
import SwiftUI

class GeneralType: TextFieldType {
    private let maxLength: Int?

    let regex: GeneralRegex
    let keyboardType: UIKeyboardType
    let disablePaste: Bool

    init(
        regex: GeneralRegex = .all,
        keyboardType: UIKeyboardType = .default,
        disablePaste: Bool = false,
        maxLength: Int? = nil)
    {
        self.regex = regex
        self.keyboardType = keyboardType
        self.disablePaste = disablePaste
        self.maxLength = maxLength
    }

    func format(_ oldText: String, _ newText: String, _ afterFormat: (String) -> Void) {
        var newText = newText

        guard newText ~= regex.pattern
        else {
            afterFormat(oldText)
            return
        }

        if
            let maxLength,
            newText.count >= maxLength
        {
            newText = String(newText[..<newText.index(newText.startIndex, offsetBy: maxLength)])
        }

        afterFormat(newText)
    }

    func onEditEnd(_: Binding<String>) {
        // do nothing.
    }
}
