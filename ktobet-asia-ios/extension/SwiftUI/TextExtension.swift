
import SwiftUI

extension Text {
    func fontAndColor(font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundColor(color)
    }
}
