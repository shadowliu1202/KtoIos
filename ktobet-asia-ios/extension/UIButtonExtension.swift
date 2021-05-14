//
//  UIButtonExtension.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/31.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIButton {
    @IBInspectable
    public var localizeTitle: String? {
        get { return title(for: .normal) }
        set { setTitle(newValue == nil ? nil : Localize.string(newValue!), for: .normal)}
    }
    
    var isValid: Bool {
        get {
            return self.isEnabled
        }
        set {
            self.isEnabled = newValue
            self.alpha = newValue ? 1 : 0.3
        }
    }
    
    public var allImage: UIImage? {
        get { return image(for: .normal) }
        set {
            setImage(newValue, for: .normal)
            setImage(newValue, for: .selected)
            setImage(newValue, for: .highlighted)
            setImage(newValue, for: .disabled)
            setImage(newValue, for: .focused)
            setImage(newValue, for: .reserved)
        }
    }
    
    func applyGradient(colors: [CGColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = self.bounds
        self.layer.insertSublayer(gradientLayer, at: 0)
    }

}

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage()}

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }

    func setBackgroundColor(color: UIColor, forUIControlState state: UIControl.State) {
        self.setBackgroundImage(imageWithColor(color: color), for: state)
    }
}


extension Reactive where Base: UIButton {
    public var touchUpInside: ControlEvent<Void> {
        self.controlEvent(.touchUpInside)
    }
}
