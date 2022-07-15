
import SwiftUI
import CoreGraphics

struct CustomizedDivider: View {
    let color: Color = .primaryGray
    let lineWeight: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .foregroundColor(color)
            .frame(height: lineWeight)
    }
}

struct CustomizedDivider_Previews: PreviewProvider {
    static var previews: some View {
        CustomizedDivider()
            .previewLayout(.sizeThatFits)
    }
}
