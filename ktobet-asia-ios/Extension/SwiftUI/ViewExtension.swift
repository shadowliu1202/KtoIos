
import Combine
import CoreGraphics
import SwiftUI

extension View {
    @ViewBuilder
    func applyTransform(
        when condition: Bool,
        transformClosure: @escaping (_ contentView: Self) -> some View)
        -> some View
    {
        if condition {
            transformClosure(self)
        }
        else {
            self
        }
    }
    
    func onTapGestureForced(count: Int = 1, perform action: @escaping () -> Void) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture(count:count, perform:action)
    }
}
