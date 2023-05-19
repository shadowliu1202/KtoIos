
import Combine
import CoreGraphics
import SwiftUI

extension View {
  @ViewBuilder
  func applyTransform(
    when condition: Bool,
    transformClosure: @escaping (_ contentView: Self) -> some View)
    -> some View
  {
    if condition {
      transformClosure(self)
    }
    else {
      self
    }
  }
}
