//
//  UIViewExtension.swift
//  ktobet-asia-ios
//
//  Created by Leo Hsu on 2021/3/4.
//

import UIKit

extension UIView {
    func addBorderTop(size: CGFloat, color: UIColor, width: CGFloat? = nil) {
        if let width = width {
            let x = (frame.width - width) / 2
            addBorderUtility(x: x, y: 0, width: width, height: size, color: color)
        } else {
            addBorderUtility(x: 0, y: 0, width: frame.width, height: size, color: color)
        }
    }
    
    func addBorderBottom(size: CGFloat, color: UIColor, width: CGFloat? = nil) {
        if let width = width {
            let x = (frame.width - width) / 2
            addBorderUtility(x: x, y: frame.height - size, width: width, height: size, color: color)
        } else {
            addBorderUtility(x: 0, y: frame.height - size, width: frame.width, height: size, color: color)
        }
    }
    
    func addBorderLeft(size: CGFloat, color: UIColor) {
        addBorderUtility(x: 0, y: 0, width: size, height: frame.height, color: color)
    }
    
    func addBorderRight(size: CGFloat, color: UIColor) {
        addBorderUtility(x: frame.width - size, y: 0, width: size, height: frame.height, color: color)
    }
    
    private func addBorderUtility(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: x, y: y, width: width, height: height)
        layer.addSublayer(border)
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
}

extension UIView {
    
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
