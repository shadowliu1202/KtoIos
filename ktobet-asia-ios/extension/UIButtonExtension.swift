//
//  UIButtonExtension.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/31.
//

import Foundation
import UIKit

extension UIButton {
    var isValid: Bool {
        get {
            return self.isValid
        }
        set {
            self.isEnabled = newValue
            self.alpha = newValue ? 1 : 0.3
        }
    }
}
