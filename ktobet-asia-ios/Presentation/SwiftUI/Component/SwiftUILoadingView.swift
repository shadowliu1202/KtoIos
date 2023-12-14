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
  private let opacity: Double
  
  init(
    style: SwiftUILoadingView.Style = .large,
    opacity: Double = 1)
  {
    self.style = style
    self.opacity = opacity
  }
  
  var body: some View {
    Rectangle()
      .fill(Color.from(.greyScaleDefault).opacity(opacity))
      .ignoresSafeArea(.container)
      .overlay(
        Image(style == .large ? "icon.loading.L" : "icon.loading.S")
          .rotationEffect(.degrees(isSpinning ? 360 : 0))
          .animation(
            Animation.linear(duration: 1)
              .repeatForever(autoreverses: false),
            value: isSpinning)
          .onAppear {
            isSpinning = true
          })
  }
}

struct SwiftUILoadingView_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUILoadingView()
  }
}
