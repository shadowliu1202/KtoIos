import SwiftUI

struct SwiftUILoadingView: View {
  @State private var isSpinning = false
  
  private let opacity: Double

  init(opacity: Double = 1) {
    self.opacity = opacity
  }
  
  var body: some View {
    Rectangle()
      .fill(Color.from(.greyScaleDefault).opacity(opacity))
      .ignoresSafeArea(.container)
      .overlay(
        Image("icon.loading")
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
