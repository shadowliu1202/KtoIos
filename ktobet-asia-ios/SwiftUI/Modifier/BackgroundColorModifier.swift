import SwiftUI

struct BackgroundColorModifier: ViewModifier {
  private let color: UIColor
  private let alpha: CGFloat
  private let cornerRadius: CGFloat

  init(
    _ color: UIColor,
    _ alpha: CGFloat,
    _ cornerRadius: CGFloat)
  {
    self.color = color
    self.alpha = alpha
    self.cornerRadius = cornerRadius
  }

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(
            Color.from(color, alpha: alpha)))
  }
}

struct BackgroundColorModifier_Previews: PreviewProvider {
  static var previews: some View {
    Text("Hello, world!")
      .foregroundColor(.white)
      .backgroundColor(.blue)
  }
}

extension View {
  func backgroundColor(
    _ color: UIColor,
    alpha: CGFloat = 1,
    cornerRadius: CGFloat = 0)
    -> some View
  {
    modifier(BackgroundColorModifier(color, alpha, cornerRadius))
  }
}
