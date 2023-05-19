import SwiftUI

struct StrokeBorderModifier: ViewModifier {
  private let color: UIColor
  private let cornerRadius: CGFloat
  private let lineWidth: CGFloat

  init(
    _ color: UIColor,
    _ cornerRadius: CGFloat,
    _ lineWidth: CGFloat)
  {
    self.color = color
    self.cornerRadius = cornerRadius
    self.lineWidth = lineWidth
  }

  func body(content: Content) -> some View {
    content
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(lineWidth: lineWidth)
          .foregroundColor(.from(color)))
  }
}

struct StrokeBorderModifier_Previews: PreviewProvider {
  static var previews: some View {
    Text("Hello, world!")
      .strokeBorder(color: .blue)
  }
}

extension View {
  func strokeBorder(
    color: UIColor,
    cornerRadius: CGFloat = 0,
    lineWidth: CGFloat = 1)
    -> some View
  {
    modifier(StrokeBorderModifier(color, cornerRadius, lineWidth))
  }
}
