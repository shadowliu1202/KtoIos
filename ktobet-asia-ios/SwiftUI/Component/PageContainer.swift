import SwiftUI

struct PageContainer<Content: View>: View {
  private let topPadding: CGFloat
  private let bottomPadding: CGFloat

  private let backgroundColor: UIColor

  private let content: Content

  init(
    backgroundColor: UIColor = .clear,
    topPadding: CGFloat = 26,
    bottomPadding: CGFloat = 96,
    @ViewBuilder content: () -> Content)
  {
    self.backgroundColor = backgroundColor
    self.topPadding = topPadding
    self.bottomPadding = bottomPadding
    self.content = content()
  }

  var body: some View {
    ZStack {
      Color.from(backgroundColor)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        content
      }
      .padding(.top, topPadding)
      .padding(.bottom, bottomPadding)
    }
  }
}

struct PageContainer_Previews: PreviewProvider {
  static var previews: some View {
    PageContainer(backgroundColor: .greyScaleDefault) {
      Text("Hello")
        .localized(weight: .medium, size: 16, color: .white)
      LimitSpacer(30)
      Text("world")
        .localized(weight: .medium, size: 16, color: .white)
      LimitSpacer(30)
      Text("!")
        .localized(weight: .medium, size: 16, color: .white)
    }

    PageContainer(backgroundColor: .greyScaleDefault) {
      VStack(spacing: 30) {
        Text("Hello2")
          .localized(weight: .medium, size: 16, color: .white)

        Text("world2")
          .localized(weight: .medium, size: 16, color: .white)

        Text("!2")
          .localized(weight: .medium, size: 16, color: .white)
      }
    }
  }
}
