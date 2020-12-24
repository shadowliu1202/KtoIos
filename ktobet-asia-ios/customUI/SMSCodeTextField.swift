//
//  OtpCodeTextField.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/22.
//

import Foundation
import UIKit


protocol SMSCodeTextFieldDelegate: AnyObject {
    func textFieldDidDelete(_ sender : SMSCodeTextField)
}

class SMSCodeTextField: UITextField {
    
    weak var myDelegate: SMSCodeTextFieldDelegate?
    private var emptyCount = 0
    
    override func deleteBackward() {
        super.deleteBackward()
        myDelegate?.textFieldDidDelete(self)
    }
}
