import SwiftUI

struct Fill: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    ButtonStyleContent { isEnabled in
      configuration.label
        .foregroundColor(isEnabled ? .from(.greyScaleWhite) : .from(.greyScaleWhite, alpha: 0.4))
        .background(
          RoundedRectangle(cornerRadius: 8)
            .foregroundColor(isEnabled ? .from(.primaryDefault) : .from(.primaryDefault, alpha: 0.3)))
        .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
  }
}

struct Fill_Previews: PreviewProvider {
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
              .padding(10)
          })
          .buttonStyle(.fill)
          .frame(width: 150)
        
        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
              .padding(10)
          })
          .buttonStyle(.fill)
          .frame(width: 150)
          .disabled(true)
      }
    }
  }

  static var previews: some View {
    Preview()
  }
}

extension ButtonStyle where Self == Fill {
  static var fill: Fill { self.init() }
}
