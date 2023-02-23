import SwiftUI

struct PageContainer<Content: View>: View {
  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      LimitSpacer(26)
      content
      LimitSpacer(96)
    }
  }
}

struct PageContainer_Previews: PreviewProvider {
  static var previews: some View {
    PageContainer {
      Rectangle().foregroundColor(.black)
    }
  }
}
