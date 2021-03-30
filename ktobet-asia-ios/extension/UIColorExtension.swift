//
//  UIColorExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/29.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


extension UIColor {
    @nonobjc class var iconWhite: UIColor {
        return UIColor(white: 230.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var backgroundSidebarMineShaftGray: UIColor {
        return UIColor(white: 32.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var yellowFull: UIColor {
        return UIColor(red: 1.0, green: 213.0 / 255.0, blue: 0.0, alpha: 1.0)
    }
    @nonobjc class var orangeFull: UIColor {
        return UIColor(red: 1.0, green: 128.0 / 255.0, blue: 0.0, alpha: 1.0)
    }
    @nonobjc class var inputSelectedTundoraGray: UIColor {
        return UIColor(white: 69.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var inputBaseMineShaftGray: UIColor {
        return UIColor(white: 51.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var textPrimaryDustyGray: UIColor {
        return UIColor(white: 155.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var whiteFull: UIColor {
        return UIColor(white: 1.0, alpha: 1.0)
    }
    @nonobjc class var redForLightFull: UIColor {
        return UIColor(red: 217.0 / 255.0, green: 1.0 / 255.0, blue: 1.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var textSecondaryScorpionGray: UIColor {
        return UIColor(white: 89.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var white15: UIColor {
        return UIColor(white: 1.0, alpha: 0.15)
    }
    @nonobjc class var white40: UIColor {
        return UIColor(white: 1.0, alpha: 0.4)
    }
    @nonobjc class var toastIconSuccessedGreen: UIColor {
        return UIColor(red: 17.0 / 255.0, green: 103.0 / 255.0, blue: 57.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var toastBackgroundGray: UIColor {
        return UIColor(white: 43.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var black_two: UIColor {
        return UIColor(red: 19.0/255.0, green: 19.0/255.0, blue: 19.0/255.0, alpha: 1.0)
    }
    @nonobjc class var black80: UIColor {
        return UIColor(white: 19.0 / 255.0, alpha: 0.8)
    }
    @nonobjc class var backgroundTabsGray: UIColor {
        return UIColor(red: 99.0 / 255.0, green: 99.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var backgroundTabsGray2: UIColor {
        return UIColor(red: 118.0 / 255.0, green: 118.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.12)
    }
    @nonobjc class var yellow50: UIColor {
        return UIColor(red: 1.0, green: 213.0 / 255.0, blue: 0.0, alpha: 0.5)
    }
    @nonobjc class var backgroundChatWindowMineShaftG2: UIColor {
        return UIColor(white: 48.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var iconBlack2: UIColor {
        return UIColor(white: 0.0, alpha: 1.0)
    }
    @nonobjc class var redForDark502: UIColor {
        return UIColor(red: 242.0 / 255.0, green: 0.0, blue: 0.0, alpha: 0.5)
    }
    @nonobjc class var iconGray: UIColor {
        return UIColor(white: 92.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var dividerCapeCodGray2: UIColor {
        return UIColor(red: 60.0 / 255.0, green: 62.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var backgroundListCodGray2: UIColor {
        return UIColor(white: 26.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var black902: UIColor {
        return UIColor(white: 19.0 / 255.0, alpha: 0.9)
    }
    @nonobjc class var yellow302: UIColor {
        return UIColor(red: 1.0, green: 213.0 / 255.0, blue: 0.0, alpha: 0.3)
    }
    @nonobjc class var textSuccessedGreen: UIColor {
        return UIColor(red: 106.0 / 255.0, green: 179.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var red: UIColor {
        return UIColor(red: 242.0 / 255.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
    @nonobjc class var redForDark50230: UIColor {
        return UIColor(red: 242.0 / 255.0, green: 0.0, blue: 0.0, alpha: 0.3)
    }
    @nonobjc class var redForDarkFull: UIColor {
      return UIColor(red: 242.0 / 255.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red   = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue  = CGFloat((hex & 0xFF)) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    struct KoyomiColor {
        
        // Using [iOS 7 colors] as reference.
        // http://ios7colors.com/
        
        static let lightBlack: UIColor  = .init(hex: 0x4A4A4A)
        static let black: UIColor       = .init(hex: 0x2B2B2B)
        static let darkBlack: UIColor   = .init(hex: 0x1F1F21)
        static let lightGray: UIColor   = .init(hex: 0xDBDDDE)
        static let darkGray: UIColor    = .init(hex: 0x8E8E93)
        static let lightYellow: UIColor = .init(hex: 0xFFDB4C)
        static let lightPurple: UIColor = .init(hex: 0xC86EDF)
        static let lightGreen: UIColor  = .init(hex: 0xA4E786)
        static let lightPink: UIColor   = .init(hex: 0xFFD3E0)
        
        // Using [iOS Human Interface Guidelines] as reference.
        // https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/
        
        static let red: UIColor      = .init(hex: 0xff3b30)
        static let orange: UIColor   = .init(hex: 0xff9500)
        static let green: UIColor    = .init(hex: 0x4cd964)
        static let blue: UIColor     = .init(hex: 0x007aff)
        static let purple: UIColor   = .init(hex: 0x5856d6)
        static let yellow: UIColor   = .init(hex: 0xffcc00)
        static let tealBlue: UIColor = .init(hex: 0x5ac8fa)
        static let pink: UIColor     = .init(hex: 0xff2d55)
    }
}
