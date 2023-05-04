import SwiftUI

struct ClearBorder: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled

  var size: CGFloat = 16

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(isEnabled ? .from(.redF20000) : .from(.gray595959))
      .localized(
        weight: .regular,
        size: size)
      .padding(10)
      .frame(maxWidth: .infinity)
      .lineLimit(1)
      .frame(height: 48)
      .stroke(color: .gray595959, cornerRadius: 8)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
  }
}

extension ButtonStyle where Self == ClearBorder {
  static var clearBorder: ClearBorder { self.init() }
}
