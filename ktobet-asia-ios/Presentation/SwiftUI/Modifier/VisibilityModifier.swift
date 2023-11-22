import SwiftUI

extension VisibilityModifier {
  enum Visibility {
    case visible
    case invisible
    case gone
  }
}

struct VisibilityModifier: ViewModifier {
  private let visibility: Visibility

  init(_ visibility: Visibility) {
    self.visibility = visibility
  }

  func body(content: Content) -> some View {
    switch visibility {
    case .visible:
      content
    case .invisible:
      content
        .hidden()
    case .gone:
      EmptyView()
    }
  }
}

struct VisibilityModifier_Previews: PreviewProvider {
  static var previews: some View {
    Text("Hello, world!")
      .visibility(.visible)
  }
}

extension View {
  func visibility(_ visibility: VisibilityModifier.Visibility) -> some View {
    modifier(VisibilityModifier(visibility))
  }
}
