import SwiftUI

struct RedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label.foregroundColor(isEnabled ? .white : .white40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.custom("PingFangSC-Regular", size: 14))
            .padding(10)
            .lineLimit(1)
            .background(RoundedRectangle(cornerRadius: 8)
                            .frame(height: 48)
                            .foregroundColor(isEnabled ? .primaryRed : .primaryRed30))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
