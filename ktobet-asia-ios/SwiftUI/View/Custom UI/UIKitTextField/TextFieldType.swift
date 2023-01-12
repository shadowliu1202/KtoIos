import Foundation
import SwiftUI
import UIKit

protocol TextFieldType: AnyObject {
    associatedtype T: TextFieldRegex
    
    var regex: T { get }
    var keyboardType: UIKeyboardType? { get }
    var disablePaste: Bool? { get }
    
    func format(_ oldText: String, _ newText: String ,_ text: Binding<String>)
    func onEditEnd(_ text: Binding<String>)
}

extension TextFieldType {
    var functionalConfig: (PasteableTextField) -> Void {
        return { [weak self] textField in
            if let keyboardType = self?.keyboardType {
                textField.keyboardType = keyboardType
            }
            
            if let disablePaste = self?.disablePaste {
                textField.disablePaste = disablePaste
            }
        }
    }
}
