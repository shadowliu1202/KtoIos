import SwiftUI

struct ConfirmRed: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .from(.whitePure) : .from(.whitePure, alpha: 0.4))
            .font(.custom("PingFangSC-Regular", size: 14))
            .padding(10)
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: 48)
                    .foregroundColor(isEnabled ? .from(.redF20000) : .from(.redF20000, alpha: 0.3))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == ConfirmRed {
    static var confirmRed: ConfirmRed { get { self.init() } }
}
