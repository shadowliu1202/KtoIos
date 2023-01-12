import Foundation
import SwiftUI

class GeneralType: TextFieldType {
    private let maxLength: Int?
    
    let regex: GeneralRegex
    let keyboardType: UIKeyboardType?
    let disablePaste: Bool?
    
    init(
        regex: GeneralRegex = .all,
        keyboardType: UIKeyboardType? = .default,
        disablePaste: Bool? = false,
        maxLength: Int? = nil
    ) {
        self.regex = regex
        self.keyboardType = keyboardType
        self.disablePaste = disablePaste
        self.maxLength = maxLength
    }
    
    func format(_ oldText: String, _ newText: String ,_ text: Binding<String>) {
        var newText = newText
        
        guard newText ~= regex.pattern
        else {
            text.wrappedValue = oldText
            return
        }
        
        if let maxLength = maxLength,
           newText.count >= maxLength {
            newText = String(newText[..<newText.index(newText.startIndex, offsetBy: maxLength)])
        }
        
        text.wrappedValue = newText
    }
    
    func onEditEnd(_ text: Binding<String>) {
        //do nothing.
    }
}
