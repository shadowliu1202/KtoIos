
import SwiftUI
import CoreGraphics

extension View {
    func customizedStrokeBorder(color: Color, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(color)
            )
    }
    
    func backgroundColor(_ color: Color) -> some View {
        self
            .background(
                color
            )
    }
    
    func KTOPageSpacer() -> some View {
        VStack(spacing: 0) {
            HeightSpacer(78)
            self
            HeightSpacer(96)
        }
    }
}
