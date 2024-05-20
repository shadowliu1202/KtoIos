import CoreGraphics
import SwiftUI

/// - Default color = greyScaleDivider
/// - Default lineWidth = 1
struct Separator: View {
    var color: UIColor = .greyScaleDivider
    var lineWidth: CGFloat = 1

    var body: some View {
        Rectangle()
            .foregroundColor(.from(color))
            .frame(height: lineWidth)
    }
}

struct Separator_Previews: PreviewProvider {
    static var previews: some View {
        Separator()
            .previewLayout(.sizeThatFits)
    }
}
