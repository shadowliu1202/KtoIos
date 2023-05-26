import SwiftUI

struct ConfirmRed: ButtonStyle {
  private let size: CGFloat

  init(size: CGFloat = 14) {
    self.size = size
  }

  func makeBody(configuration: Self.Configuration) -> some View {
    ButtonStyleContent { isEnabled in
      configuration.label
        .foregroundColor(isEnabled ? .from(.greyScaleWhite) : .from(.greyScaleWhite, alpha: 0.4))
        .localized(
          weight: .regular,
          size: size)
        .padding(10)
        .frame(maxWidth: .infinity)
        .lineLimit(1)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .frame(height: 48)
            .foregroundColor(isEnabled ? .from(.primaryDefault) : .from(.primaryDefault, alpha: 0.3)))
        .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
  }
}

struct ConfirmRed_Previews: PreviewProvider {
  struct Preview: View {
    @State private var isSelected = true

    var body: some View {
      VStack(spacing: 20) {
        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
          })
          .buttonStyle(.confirmRed)
          .frame(width: 150)

        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
          })
          .buttonStyle(.confirmRed)
          .frame(width: 150)
          .disabled(true)
      }
    }
  }

  static var previews: some View {
    Preview()
  }
}

extension ButtonStyle where Self == ConfirmRed {
  static var confirmRed: ConfirmRed { self.init() }

  static func confirmRed(size: CGFloat) -> ConfirmRed { self.init(size: size) }
}
