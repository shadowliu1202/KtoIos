//
//  ReactiveExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/24.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base : UIButton {
    public var valid : Binder<Bool> {
        return Binder(self.base) { button, valid in
            button.isEnabled = valid
            button.alpha = valid ? 1 : 0.3
        }
    }
}
