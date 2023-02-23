import SwiftUI

struct BannerView: View {
  var body: some View {
    VStack {
      HStack {
        Spacer().frame(width: 16.0)
        Image("Disconnected")
        Spacer().frame(width: 16.0)
        Text(Localize.string("common_network_error"))
          .foregroundColor(Color(.whitePure))
          .font(Font.custom("PingFangSC-Regular", size: 14))
        Spacer()
        GradientIndicatorView(colors: [Color(.whitePure), Color(.clear)], lineCap: .butt)
          .frame(width: 18.0, height: 18.0, alignment: .center)
        Spacer().frame(width: 17.0)
      }.frame(height: 52.0)
    }
    .background(Color(red: 255 / 255, green: 128 / 255, blue: 0, opacity: 0.8))
  }
}

struct GradientIndicatorView: View {
  let colors: [Color]
  let lineCap: CGLineCap

  @State private var rotation: Double = 0

  var body: some View {
    let gradientColors = Gradient(colors: colors)
    let conic = AngularGradient(gradient: gradientColors, center: .center, startAngle: .zero, endAngle: .degrees(360))
    let lineWidth: CGFloat = 2

    let animation = Animation
      .linear(duration: 1.5)
      .repeatForever(autoreverses: false)

    return ZStack {
      Circle()
        .stroke(colors.first ?? .white, lineWidth: lineWidth)

      Circle()
        .trim(from: lineWidth / 500, to: 1 - lineWidth / 100)
        .stroke(conic, style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
        .rotationEffect(.degrees(rotation))
        .onAppear {
          self.rotation = 0
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(animation) {
              self.rotation = 360
            }
          }
        }
    }
  }
}

struct BannerView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      BannerView()
    }
    .previewLayout(.fixed(width: 375, height: 152))
  }
}
