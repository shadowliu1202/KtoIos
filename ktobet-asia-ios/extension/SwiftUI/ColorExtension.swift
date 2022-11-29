import SwiftUI

extension Color {
    
    static func from(_ uiColor: UIColor, alpha: CGFloat = 1) -> Color {
        Color(uiColor.withAlphaComponent(alpha))
    }
}
