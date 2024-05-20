import Lottie
import SwiftUI

struct SwiftUILottieView: UIViewRepresentable {
    @Binding var isAnimationPlaying: Bool
  
    let lottieFile: String
  
    let animationView = AnimationView()
  
    func makeUIView(context _: Context) -> some UIView {
        let view = UIView(frame: .zero)
    
        animationView.animation = .named(lottieFile)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
    
        view.addSubview(animationView)
    
        animationView.snp.makeConstraints { make in
            make.width.height.equalToSuperview()
        }
  
        return view
    }
  
    func updateUIView(_: UIViewType, context: Context) {
        if $isAnimationPlaying.wrappedValue {
            context.coordinator.parent.animationView.play()
        }
        else {
            context.coordinator.parent.animationView.stop()
        }
    }
  
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SwiftUILottieView

        init(_ parent: SwiftUILottieView) {
            self.parent = parent
        }
    }
}
