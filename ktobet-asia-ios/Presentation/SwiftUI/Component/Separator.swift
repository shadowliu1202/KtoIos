import CoreGraphics
import SwiftUI

/// - Default color = greyScaleDivider
/// - Default lineWeight = 1
struct Separator: View {
  var color: UIColor = .greyScaleDivider
  var lineWeight: CGFloat = 1

  var body: some View {
    Rectangle()
      .foregroundColor(.from(color))
      .frame(height: lineWeight)
  }
}

struct Separator_Previews: PreviewProvider {
  static var previews: some View {
    Separator()
      .previewLayout(.sizeThatFits)
  }
}
