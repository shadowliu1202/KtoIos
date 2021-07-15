import UIKit

public enum BorderSide: Int {
    case top, bottom, left, right, around
}

extension UIView {
    public func addBorder(_ side: BorderSide, size: CGFloat, color: UIColor, rightConstant: CGFloat = 0, leftConstant: CGFloat = 0) {
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
        default: break
        }
    }
    
    public func remove(side: BorderSide) {
        if side == .around {
            self.borderWidth = 0
            self.bordersColor = nil
            return
        }
        var borderForRemove: UIView?
        for border in self.subviews {
            if border.tag == side.rawValue {
                borderForRemove = border
            }
        }
        if let border = borderForRemove {
            border.removeFromSuperview()
        }
    }
    
    enum EdgeDirection { case left, right, none }
    
    func mask(with style: EdgeDirection) {
        let center = style.center(of: bounds)
        let path: UIBezierPath = .init()
        path.move(to: center)
        path.addArc(withCenter: center, radius: bounds.height / 2, startAngle: style.angle.start, endAngle: style.angle.end, clockwise: style.isClockwise)
        
        let maskLayer: CAShapeLayer = .init()
        maskLayer.frame = bounds
        maskLayer.path  = path.cgPath
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
    
    @IBInspectable
       var borderWidth: CGFloat {
          get {
             return layer.borderWidth
          }
          set {
             layer.borderWidth = newValue
          }
       }
       @IBInspectable
       var bordersColor: UIColor? {
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
    @IBInspectable
    public var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set {
            self.clipsToBounds = true
            layer.cornerRadius = newValue
        }
    }
    @IBInspectable
    public var masksToBounds: Bool {
        get { return layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
}

extension UIView.EdgeDirection {
    var angle: (start: CGFloat, end: CGFloat) {
        switch self {
        case .left, .right: return (start: .pi + (.pi / 2), end: .pi / 2)
        case .none: return (start: 0, end: 0)
        }
    }
    
    var isClockwise: Bool {
        switch self {
        case .left: return false
        default:    return true
        }
    }
    
    func center(of bounds: CGRect) -> CGPoint {
        switch self {
        case .left: return CGPoint(x: bounds.width, y: bounds.height / 2)
        default:    return CGPoint(x: 0, y: bounds.height / 2)
        }
    }
}


enum ViewBorder: String {
    case left, right, top, bottom
}

extension UIView {
    func add(border: ViewBorder, color: UIColor, width: CGFloat) {
        let borderLayer = CALayer()
        borderLayer.backgroundColor = color.cgColor
        borderLayer.name = border.rawValue
        switch border {
        case .left:
            borderLayer.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        case .right:
            borderLayer.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        case .top:
            borderLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        case .bottom:
            borderLayer.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        }
        self.layer.addSublayer(borderLayer)
    }

    func remove(border: ViewBorder) {
        guard let sublayers = self.layer.sublayers else { return }
        var layerForRemove: CALayer?
        for layer in sublayers {
            if layer.name == border.rawValue {
                layerForRemove = layer
            }
        }
        if let layer = layerForRemove {
            layer.removeFromSuperlayer()
        }
    }

}

extension UIView {
    func setViewCorner(topCorner : Bool, bottomCorner : Bool){
        layer.masksToBounds = true
        layer.cornerRadius = 8
        if topCorner && bottomCorner{
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if topCorner {
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if bottomCorner{
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
}
