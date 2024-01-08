import Foundation
import sharedbu

extension KotlinBoolean {
  func toBool() -> Bool {
    Bool(truncating: self)
  }
}
