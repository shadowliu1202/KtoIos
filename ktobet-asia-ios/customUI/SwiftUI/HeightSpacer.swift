
import SwiftUI
import CoreGraphics

struct HeightSpacer: View {
    let height: CGFloat
    
    init(_ height: CGFloat) {
        self.height = height
    }
    var body: some View {
        Spacer()
            .frame(height: height)
    }
}

struct HeightSpacer_Previews: PreviewProvider {
    static var previews: some View {
        HeightSpacer(5)
    }
}
