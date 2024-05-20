import SwiftUI

// In iOS 14.4, buttonStyle can't get @Environment(\.isEnabled),
// so we need to use this way to get enable status.

struct ButtonStyleContent<Content: View>: View {
    @Environment(\.isEnabled) var isEnabled: Bool

    private let content: (_ isEnabled: Bool) -> Content

    init(@ViewBuilder content: @escaping (_ isEnabled: Bool) -> Content) {
        self.content = content
    }

    var body: some View {
        content(isEnabled)
    }
}
