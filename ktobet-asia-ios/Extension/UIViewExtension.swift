import UIKit

public enum BorderSide: Int, CaseIterable {
    case top = 1100
    case bottom
    case left
    case right
    case around
}

extension UIView {
    func addBorder(
        _ side: BorderSide = .top,
        size: CGFloat = 1,
        color: UIColor = .greyScaleDivider,
        rightConstant: CGFloat = 0,
        leftConstant: CGFloat = 0)
    {
        if side == .around {
            self.borderWidth = size
            self.bordersColor = color
            return
        }
        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.backgroundColor = color
        border.tag = side.rawValue
        self.addSubview(border)

        let topConstraint = topAnchor.constraint(equalTo: border.topAnchor)
        let rightConstraint = trailingAnchor.constraint(equalTo: border.trailingAnchor, constant: rightConstant)
        let bottomConstraint = bottomAnchor.constraint(equalTo: border.bottomAnchor)
        let leftConstraint = border.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftConstant)
        let heightConstraint = border.heightAnchor.constraint(equalToConstant: size)
        let widthConstraint = border.widthAnchor.constraint(equalToConstant: size)

        switch side {
        case .top:
            NSLayoutConstraint.activate([leftConstraint, topConstraint, rightConstraint, heightConstraint])
        case .right:
            NSLayoutConstraint.activate([topConstraint, rightConstraint, bottomConstraint, widthConstraint])
        case .bottom:
            NSLayoutConstraint.activate([rightConstraint, bottomConstraint, leftConstraint, heightConstraint])
        case .left:
            NSLayoutConstraint.activate([bottomConstraint, leftConstraint, topConstraint, widthConstraint])
        case .around:
            break
        }
    }

    public func removeBorder(_ side: BorderSide = .top) {
        if side == .around {
            self.borderWidth = 0
            self.bordersColor = nil
            return
        }
        for border in self.subviews {
            if border.tag == side.rawValue {
                border.removeFromSuperview()
            }
        }
    }

    public func removeAllBorder() {
        for view in subviews {
            if BorderSide.allCases.map({ $0.rawValue }).contains(view.tag) {
                view.removeFromSuperview()
            }
        }
    }

    enum EdgeDirection { case left
        case right
        case none
    }

    func mask(with style: EdgeDirection) {
        let center = style.center(of: bounds)
        let path: UIBezierPath = .init()
        path.move(to: center)
        path.addArc(
            withCenter: center,
            radius: bounds.height / 2,
            startAngle: style.angle.start,
            endAngle: style.angle.end,
            clockwise: style.isClockwise)

        let maskLayer: CAShapeLayer = .init()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        layer.mask = style == .none ? nil : maskLayer
    }

    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 2
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }

    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }

    func applyGradient(horizontal colors: [CGColor]) {
        self.applyGradient(startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5), colors: colors)
    }

    func applyGradient(vertical colors: [CGColor]) {
        self.applyGradient(startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1), colors: colors)
    }

    func applyGradient(startPoint: CGPoint, endPoint: CGPoint, colors: [CGColor]) {
        DispatchQueue.main.async {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = colors
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            gradientLayer.frame = self.bounds
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
    }

    func gradientLayer(horizontal colors: [CGColor]) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientLayer
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var bordersColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            }
            else {
                layer.borderColor = nil
            }
        }
    }

    @IBInspectable public var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set {
            self.clipsToBounds = true
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable public var masksToBounds: Bool {
        get { layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
}

extension UIView.EdgeDirection {
    var angle: (start: CGFloat, end: CGFloat) {
        switch self {
        case .left,
             .right: return (start: .pi + (.pi / 2), end: .pi / 2)
        case .none: return (start: 0, end: 0)
        }
    }

    var isClockwise: Bool {
        self != .left
    }

    func center(of bounds: CGRect) -> CGPoint {
        switch self {
        case .left: return CGPoint(x: bounds.width, y: bounds.height / 2)
        case .none,
             .right:
            return CGPoint(x: 0, y: bounds.height / 2)
        }
    }
}

enum ViewBorder: String {
    case left
    case right
    case top
    case bottom
}

extension UIView {
    public func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        layer.masksToBounds = true
        if #available(iOS 11, *) {
            var cornerMask = CACornerMask()
            if corners.contains(.topLeft) {
                cornerMask.insert(.layerMinXMinYCorner)
            }
            if corners.contains(.topRight) {
                cornerMask.insert(.layerMaxXMinYCorner)
            }
            if corners.contains(.bottomLeft) {
                cornerMask.insert(.layerMinXMaxYCorner)
            }
            if corners.contains(.bottomRight) {
                cornerMask.insert(.layerMaxXMaxYCorner)
            }
            self.layer.cornerRadius = radius
            self.layer.maskedCorners = cornerMask
        }
        else {
            let path = UIBezierPath(
                roundedRect: self.bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
    }

    func setViewCorner(topCorner: Bool, bottomCorner: Bool, radius: CGFloat = 8) {
        layer.masksToBounds = true
        layer.cornerRadius = radius
        if topCorner, bottomCorner {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        else if topCorner {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        else if bottomCorner {
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
}

extension UIView {
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}

extension UIView {
    func rotate() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi)
        rotation.duration = 0.6
        rotation.repeatCount = 1
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

extension UIView {
    enum Visibility: String {
        case visible
        case invisible
        case gone
    }

    var visibility: Visibility {
        get {
            let constraint = (self.constraints.filter { $0.firstAttribute == .height && $0.constant == 0 }.first)
            if let constraint, constraint.isActive {
                return .gone
            }
            else {
                return self.isHidden ? .invisible : .visible
            }
        }

        set {
            if self.visibility != newValue {
                self.setVisibility(newValue)
            }
        }
    }

    @IBInspectable var visibilityState: String {
        get {
            self.visibility.rawValue
        }

        set {
            let _visibility = Visibility(rawValue: newValue)!
            self.visibility = _visibility
        }
    }

    private func setVisibility(_ visibility: Visibility) {
        let constraints = self.constraints
            .filter({
                $0.firstAttribute == .height && $0.constant == 0 && $0.secondItem == nil && ($0.firstItem as? UIView) == self
            })
        let constraint = constraints.first

        switch visibility {
        case .visible:
            constraint?.isActive = false
            self.isHidden = false
        case .invisible:
            constraint?.isActive = false
            self.isHidden = true
        case .gone:
            self.isHidden = true
            if let constraint {
                constraint.isActive = true
            }
            else {
                let constraint = NSLayoutConstraint(
                    item: self,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .height,
                    multiplier: 1,
                    constant: 0)
                self.addConstraint(constraint)
                constraint.isActive = true
            }
            self.setNeedsLayout()
            self.setNeedsUpdateConstraints()
        }
    }
}
