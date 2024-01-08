import SwiftUI

extension SwiftUILoadingView {
  enum Style {
    case large
    case small
  }
}

struct SwiftUILoadingView: View {
  @State private var isSpinning = false
  
  private let style: SwiftUILoadingView.Style
  private let iconColor: UIColor
  private let backgroundColor: UIColor
  private let backgroundOpacity: Double
  
  init(
    style: SwiftUILoadingView.Style = .large,
    iconColor: UIColor = .greyScaleWhite,
    backgroundColor: UIColor = .greyScaleDefault,
    backgroundOpacity: Double = 1)
  {
    self.style = style
    self.iconColor = iconColor
    self.backgroundColor = backgroundColor
    self.backgroundOpacity = backgroundOpacity
  }
  
  var body: some View {
    Rectangle()
      .fill(Color.from(backgroundColor).opacity(backgroundOpacity))
      .ignoresSafeArea(.container)
      .overlay(
        Image(style == .large ? "icon.loading.L" : "icon.loading.S")
          .foregroundColor(Color.from(iconColor))
          .rotationEffect(.degrees(isSpinning ? 360 : 0))
          .animation(
            Animation.linear(duration: 1)
              .repeatForever(autoreverses: false),
            value: isSpinning)
          .onAppear {
            isSpinning = true
          })
      .frame(idealWidth: 24, idealHeight: 24)
  }
}

struct SwiftUILoadingView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUILoadingView()
  }
}
