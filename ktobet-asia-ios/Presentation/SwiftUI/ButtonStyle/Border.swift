import SwiftUI

struct Border: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    ButtonStyleContent { isEnabled in
      configuration.label
        .foregroundColor(isEnabled ? .from(.primaryDefault) : .from(.textSecondary))
        .stroke(color: .textSecondary, cornerRadius: 8)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
  }
}

struct Border_Previews: PreviewProvider {
  struct Preview: View {
    @State private var isSelected = true

    var body: some View {
      VStack {
        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
              .padding(10)
          })
          .buttonStyle(.border)

        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
              .padding(10)
          })
          .buttonStyle(.border)
          .disabled(true)
      }
    }
  }

  static var previews: some View {
    Preview()
  }
}

extension ButtonStyle where Self == Border {
  static var border: Border { self.init() }
}
