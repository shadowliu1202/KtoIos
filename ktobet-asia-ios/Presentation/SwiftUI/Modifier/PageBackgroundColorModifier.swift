import SwiftUI

struct PageBackgroundColorModifier: ViewModifier {
  private let color: UIColor
  private let alpha: CGFloat

  init(_ color: UIColor, _ alpha: CGFloat) {
    self.color = color
    self.alpha = alpha
  }

  func body(content: Content) -> some View {
    content
      .background(
        Color.from(color, alpha: alpha).ignoresSafeArea())
  }
}

struct PageBackgroundColorModifier_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Text("Hello, world!")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageBackgroundColor(.blue)
    }
  }
}

extension View {
  func pageBackgroundColor(_ color: UIColor, alpha: CGFloat = 1) -> some View {
    modifier(PageBackgroundColorModifier(color, alpha))
  }
}
