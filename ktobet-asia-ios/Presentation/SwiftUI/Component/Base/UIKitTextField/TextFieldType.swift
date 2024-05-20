import Foundation
import SwiftUI
import UIKit

protocol TextFieldType: AnyObject {
    associatedtype T: TextFieldRegex

    var regex: T { get }
    var keyboardType: UIKeyboardType { get }
    var disablePaste: Bool { get }

    func format(_ oldText: String, _ newText: String, _ afterFormat: (String) -> Void)
    func onEditEnd(_ text: Binding<String>)
}

extension TextFieldType {
    var functionalConfig: (PasteableTextField) -> Void {
        { [weak self] textField in
            guard let self else { return }

            textField.keyboardType = self.keyboardType
            textField.disablePaste = self.disablePaste
        }
    }
}
