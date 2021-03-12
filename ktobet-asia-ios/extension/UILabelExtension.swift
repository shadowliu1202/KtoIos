//
//  UILabelExtension.swift
//  ktobet-asia-ios
//
//  Created by Leo Hsu on 2021/3/4.
//

import UIKit

extension UILabel {
    
    @IBInspectable
    public var localizedtext: String? {
        get { return text }
        set { text = newValue == nil ? nil : Localize.string(newValue!) }
    }
}
