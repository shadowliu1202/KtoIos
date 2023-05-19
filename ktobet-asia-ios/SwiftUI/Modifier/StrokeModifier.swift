import SwiftUI

struct StrokeModifier: ViewModifier {
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
          .stroke(lineWidth: lineWidth)
          .foregroundColor(.from(color)))
  }
}

struct StrokeModifier_Previews: PreviewProvider {
  static var previews: some View {
    Text("Hello, world!")
      .stroke(color: .blue)
  }
}

extension View {
  func stroke(
    color: UIColor,
    cornerRadius: CGFloat = 0,
    lineWidth: CGFloat = 1)
    -> some View {
      modifier(StrokeModifier(color, cornerRadius, lineWidth))
    }
}
