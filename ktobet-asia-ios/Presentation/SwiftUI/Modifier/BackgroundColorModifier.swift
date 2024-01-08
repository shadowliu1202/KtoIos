import SwiftUI

struct BackgroundColorModifier: ViewModifier {
  private let color: UIColor
  private let alpha: CGFloat
  private let cornerRadius: CGFloat
  private let ignoreEdges: SwiftUI.Edge.Set?

  init(
    _ color: UIColor,
    _ alpha: CGFloat,
    _ cornerRadius: CGFloat,
    _ ignoresSafeArea: SwiftUI.Edge.Set? = nil)
  {
    self.color = color
    self.alpha = alpha
    self.cornerRadius = cornerRadius
    self.ignoreEdges = ignoresSafeArea
  }

  func body(content: Content) -> some View {
    if let ignoreEdges {
      ZStack {
        Color.from(color, alpha: alpha)
          .cornerRadius(cornerRadius)
          .ignoresSafeArea(edges: ignoreEdges)
        
        content
      }
    }
    else {
      content
        .background(
          Color.from(color, alpha: alpha)
            .cornerRadius(cornerRadius))
    }
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
    cornerRadius: CGFloat = 0,
    ignoresSafeArea: SwiftUI.Edge.Set? = nil)
    -> some View
  {
    modifier(BackgroundColorModifier(color, alpha, cornerRadius, ignoresSafeArea))
  }
}
