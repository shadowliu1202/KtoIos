import UIKit

class LoadingView: UIView {
  private let imageView = DrawCircles()

  init() {
    super.init(frame: .zero)
    isHidden = true
    backgroundColor = .gray131313.withAlphaComponent(0.8)

    addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.size.equalTo(48)
    }

    addLayerAnimation(to: imageView.layer, duration: 1)
  }

  private func addLayerAnimation(to layer: CALayer, duration: Double) {
    let animation = CABasicAnimation(keyPath: "transform.rotation")

    animation.fromValue = 0
    animation.toValue = Double.pi * 2
    animation.duration = CFTimeInterval(duration)
    animation.repeatCount = .infinity
    animation.timingFunction = CAMediaTimingFunction(name: .linear)

    layer.add(animation, forKey: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

private class DrawCircles: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_: CGRect) {
    let lineWidth: CGFloat = 5
    let strokeColor: UIColor = .whitePure
    let startAngle: CGFloat = 0
    let maxAngle = CGFloat(Double.pi * 2)
    let lineCapStyle: CGLineCap = .round

    let gradations = 255
    let center = CGPoint(x: bounds.origin.x + bounds.size.width / 2, y: bounds.origin.y + bounds.size.height / 2)
    let radius = (min(bounds.size.width, bounds.size.height) - lineWidth) / 2

    for i in 1...gradations {
      let percent0 = CGFloat(i - 1) / CGFloat(gradations)
      let percent1 = CGFloat(i) / CGFloat(gradations)
      let angle0 = startAngle + (maxAngle - startAngle) * percent0
      let angle1 = startAngle + (maxAngle - startAngle) * percent1

      let context = UIGraphicsGetCurrentContext()!
      context.setLineWidth(lineWidth)
      context.setLineCap(lineCapStyle)

      let path = CGMutablePath()
      path.addArc(center: center, radius: radius + lineWidth / 2, startAngle: angle0, endAngle: angle1, clockwise: true)
      path.addArc(center: center, radius: radius - lineWidth / 2, startAngle: angle1, endAngle: angle0, clockwise: false)
      path.closeSubpath()

      let colors = [strokeColor.withAlphaComponent(percent0).cgColor, strokeColor.withAlphaComponent(percent1).cgColor]
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let colorLocations: [CGFloat] = [0.0, 1.0]
      let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
      let startPoint = CGPoint(x: center.x + cos(angle0) * radius, y: center.y + sin(angle0) * radius)
      let endPoint = CGPoint(x: center.x + cos(angle1) * radius, y: center.y + sin(angle1) * radius)

      context.saveGState()
      context.addPath(path)
      context.clip()
      context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
      context.restoreGState()
    }
  }
}
