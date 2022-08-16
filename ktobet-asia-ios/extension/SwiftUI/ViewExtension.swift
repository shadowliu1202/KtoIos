
import SwiftUI
import CoreGraphics

extension View {
    @ViewBuilder
    func customizedStrokeBorder(color: Color, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(color)
            )
    }
    
    @ViewBuilder
    func backgroundColor(_ color: Color) -> some View {
        self
            .background(
                color
            )
    }
    
    @ViewBuilder
    func pageBackgroundColor(_ color: Color) -> some View {
        self
            .background(
                color
                    .ignoresSafeArea()
            )
    }
    
    @ViewBuilder
    func customizedFont(fontWeight: KTOFontWeight, size: CGFloat, color: KTOTextColor?) -> some View {
        LocalizeFont(fontWeight: fontWeight, size: size, color: color) {
            self
        }
    }
    
    @ViewBuilder
    func visibility(_ visibility: Visibility) -> some View {
        switch visibility {
        case .visible:
            self
        case .invisible:
            self.hidden()
        case .gone:
            EmptyView()
        }
    }

    @ViewBuilder
    func wrappedInScrollView(when condition: Bool, _ axis: Axis.Set = .vertical, showsIndicators: Bool = true) -> some View {
        if condition {
            ScrollView(axis, showsIndicators: showsIndicators) {
                self
            }
        } else {
            self
        }
    }
}

enum Visibility {
    case visible
    case invisible
    case gone
}
