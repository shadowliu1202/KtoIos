import SwiftUI
import UIKit

class LoadingView: UIView {
  private let imageView = GradientArcView()

  init() {
    super.init(frame: .zero)
    isHidden = true
    backgroundColor = .gray131313.withAlphaComponent(0.8)

    addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.size.equalTo(48)
    }
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

class GradientArcView: UIView {
  var startColor: UIColor = .whitePure.withAlphaComponent(0)
  var endColor: UIColor = .whitePure
  var lineWidth: CGFloat = 5

  private let gradientLayer: CAGradientLayer = {
    let gradientLayer = CAGradientLayer()
    gradientLayer.type = .conic
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
    return gradientLayer
  }()

  override init(frame: CGRect = .zero) {
    super.init(frame: frame)

    configure()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    configure()
  }
}

extension GradientArcView {
  private func configure() {
    layer.addSublayer(gradientLayer)

    DispatchQueue.main.async {
      self.updateGradient()
      self.addLayerAnimation(to: self.layer, duration: 1)
    }
  }

  private func updateGradient() {
    gradientLayer.frame = bounds
    gradientLayer.colors = [startColor, endColor].map { $0.cgColor }

    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
    let path = UIBezierPath(
      arcCenter: center,
      radius: radius,
      startAngle: 0,
      endAngle: 2 * .pi,
      clockwise: true)
    let mask = CAShapeLayer()
    mask.fillColor = UIColor.clear.cgColor
    mask.strokeColor = UIColor.white.cgColor
    mask.lineWidth = lineWidth
    mask.path = path.cgPath
    gradientLayer.mask = mask
  }

  private func addLayerAnimation(to layer: CALayer, duration: Double) {
    let animation = CABasicAnimation(keyPath: "transform.rotation")

    animation.fromValue = 0
    animation.toValue = Double.pi * 2
    animation.duration = CFTimeInterval(duration)
    animation.repeatCount = .infinity
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.isRemovedOnCompletion = false

    layer.add(animation, forKey: nil)
  }
}

struct SwiftUIGradientArcView: UIViewRepresentable {
  let isVisible: Bool

  func makeUIView(context _: Context) -> GradientArcView {
    GradientArcView(frame: .zero)
  }

  func updateUIView(_ uiView: GradientArcView, context _: Context) {
    uiView.isHidden = !isVisible
  }
}
