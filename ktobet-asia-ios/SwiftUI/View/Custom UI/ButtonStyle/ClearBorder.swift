import SwiftUI

struct ClearBorder: ButtonStyle {
  private let size: CGFloat

  init(size: CGFloat = 16) {
    self.size = size
  }

  func makeBody(configuration: Self.Configuration) -> some View {
    ButtonStyleContent { isEnabled in
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
}

struct ClearBorder_Previews: PreviewProvider {
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
          })
          .buttonStyle(.clearBorder)
          .frame(width: 150)

        Button(
          action: {
            isSelected.toggle()
          },
          label: {
            Text("Press Me")
          })
          .buttonStyle(.clearBorder)
          .frame(width: 150)
          .disabled(true)
      }
    }
  }

  static var previews: some View {
    Preview()
  }
}

extension ButtonStyle where Self == ClearBorder {
  static var clearBorder: ClearBorder { self.init() }
}
