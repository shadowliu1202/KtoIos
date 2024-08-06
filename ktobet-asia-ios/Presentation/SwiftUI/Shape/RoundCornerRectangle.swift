import Foundation
import SwiftUI

struct RoundCornerRectangle: Shape {
    var cornerRadius: CGFloat
    var corner: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corner, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        return Path(path.cgPath)
    }
}
