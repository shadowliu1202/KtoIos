//
//  UIButtonExtension.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/31.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIButton {
    @IBInspectable
    public var localizeTitle: String? {
        get { return title(for: .normal) }
        set { setTitle(newValue == nil ? nil : Localize.string(newValue!), for: .normal)}
    }
    
    var isValid: Bool {
        get {
            return self.isEnabled
        }
        set {
            self.isEnabled = newValue
            self.alpha = newValue ? 1 : 0.3
        }
    }
}

extension Reactive where Base: UIButton {
    public var touchUpInside: ControlEvent<Void> {
        self.controlEvent(.touchUpInside)
    }
}
