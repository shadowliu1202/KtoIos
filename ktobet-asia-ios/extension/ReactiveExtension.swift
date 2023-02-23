import Foundation
import RxCocoa
import RxSwift

extension Reactive where Base: UIButton {
  public var valid: Binder<Bool> {
    Binder(self.base) { button, valid in
      button.isEnabled = valid
      button.alpha = valid ? 1 : 0.3
    }
  }
}
