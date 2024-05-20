import SwiftUI

struct BannerView: View {
    var body: some View {
        HStack(spacing: 0) {
            Image("Disconnected")
            LimitSpacer(16)
            Text(key: "common_network_error")
                .localized(weight: .regular, size: 14, color: .greyScaleWhite)
                .frame(maxWidth: .infinity, alignment: .leading)
            LimitSpacer(8)
            GradientIndicator()
            LimitSpacer(8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(red: 255 / 255, green: 128 / 255, blue: 0, opacity: 0.8))
    }
}

extension BannerView {
    struct GradientIndicator: View {
        @State private var rotation: Double = 0
    
        var body: some View {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            .init(color: .from(.greyScaleWhite).opacity(0), location: 0),
                            .init(color: .from(.greyScaleWhite), location: 1)
                        ],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)),
                    lineWidth: 2)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                .frame(width: 18, height: 18)
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            Color.from(.greyScaleDefault)
                .ignoresSafeArea()
      
            BannerView()
        }
    }
}
