
import CoreGraphics
import SwiftUI

struct LimitSpacer: View {
  let pixel: CGFloat

  init(_ pixel: CGFloat) {
    self.pixel = pixel
  }

  var body: some View {
    Spacer(minLength: pixel)
      .fixedSize()
  }
}

struct LimitSpacer_Previews: PreviewProvider {
  static var previews: some View {
    LimitSpacer(5)
  }
}
