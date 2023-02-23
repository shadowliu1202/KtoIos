import CoreGraphics
import SwiftUI

struct Separator: View {
  var color: UIColor = .gray9B9B9B
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
