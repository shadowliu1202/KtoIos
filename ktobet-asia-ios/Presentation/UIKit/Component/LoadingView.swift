import SwiftUI
import UIKit

class LoadingView: UIView {
  private let imageView = GradientArcView()

  init() {
    super.init(frame: .zero)
    isHidden = true
    backgroundColor = .greyScaleDefault.withAlphaComponent(0.8)

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
  var startColor: UIColor = .greyScaleWhite.withAlphaComponent(0)
  var endColor: UIColor = .greyScaleWhite
  var lineWidth: CGFloat

  private let shapeMask = CAShapeLayer()

  private let gradientLayer: CAGradientLayer = {
    let gradientLayer = CAGradientLayer()
    gradientLayer.type = .conic
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
    return gradientLayer
  }()

  init(
    frame: CGRect = .zero,
    lineWidth: CGFloat = 5)
  {
    self.lineWidth = lineWidth
    super.init(frame: frame)

    configure()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateGradient()
  }
}

extension GradientArcView {
  private func configure() {
    shapeMask.fillColor = UIColor.clear.cgColor
    shapeMask.strokeColor = UIColor.white.cgColor
    shapeMask.lineWidth = lineWidth

    gradientLayer.colors = [startColor, endColor].map { $0.cgColor }
    gradientLayer.mask = shapeMask

    layer.addSublayer(gradientLayer)

    DispatchQueue.main.async {
      self.addLayerAnimation(to: self.layer, duration: 1)
    }
  }

  private func updateGradient() {
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
    let path = UIBezierPath(
      arcCenter: center,
      radius: radius,
      startAngle: 0,
      endAngle: 2 * .pi,
      clockwise: true)

    shapeMask.path = path.cgPath

    gradientLayer.frame = bounds
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
  var isVisible = true
  var lineWidth: CGFloat = 5

  func makeUIView(context _: Context) -> GradientArcView {
    GradientArcView(frame: .zero, lineWidth: lineWidth)
  }

  func updateUIView(_ uiView: GradientArcView, context _: Context) {
    uiView.isHidden = !isVisible
  }
}
