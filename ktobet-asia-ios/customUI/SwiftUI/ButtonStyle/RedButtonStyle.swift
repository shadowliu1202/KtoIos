import SwiftUI

struct RedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .white : .white40)
            .font(.custom("PingFangSC-Regular", size: 14))
            .padding(10)
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: 48)
                    .foregroundColor(isEnabled ? .primaryRed : .primaryRed30)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
