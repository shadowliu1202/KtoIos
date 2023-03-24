import SharedBu
import SwiftUI

struct PageLoadingModifier: ViewModifier {
  var isLoading = true

  func body(content: Content) -> some View {
    if !isLoading {
      content
    }
    else {
      VStack {
        SwiftUIGradientArcView(lineWidth: 5)
          .frame(width: 48, height: 48)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

extension View {
  func onPageLoading(_ isLoading: Bool) -> some View {
    self.modifier(PageLoadingModifier(isLoading: isLoading))
  }
}
