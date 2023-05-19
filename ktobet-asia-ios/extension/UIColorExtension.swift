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
      blue: rgb & 0xFF)
  }
}

extension UIColor {
  static let greyScaleBlack: UIColor = .init(hex: 0x000000)
  static let greyScaleDefault: UIColor = .init(hex: 0x131313)
  static let greyScaleWhite: UIColor = .init(hex: 0xFFFFFF)
  static let greyScaleList: UIColor = .init(hex: 0x1A1A1A)
  static let greyScaleSidebar: UIColor = .init(hex: 0x202020)
  static let greyScaleToast: UIColor = .init(hex: 0x2B2B2B)
  static let greyScaleChatWindow: UIColor = .init(hex: 0x303030)
  static let greyScaleDivider: UIColor = .init(hex: 0x3C3E40)
  static let greyScaleIconDisable: UIColor = .init(hex: 0x5C5C5C)
  static let greyScaleIcon: UIColor = .init(hex: 0xE6E6E6)

  static let textPrimary: UIColor = .init(hex: 0x9B9B9B)
  static let textSecondary: UIColor = .init(hex: 0x595959)

  static let inputDefault: UIColor = .init(hex: 0x333333)
  static let inputFocus: UIColor = .init(hex: 0x454545)

  static let primaryDefault: UIColor = .init(hex: 0xF20000)
  static let primaryForLight: UIColor = .init(hex: 0xD90101)
  
  static let complementaryDefault: UIColor = .init(hex: 0xFED500)
  
  static let alert: UIColor = .init(hex: 0xFF8000)
  
  static let statusSuccess: UIColor = .init(hex: 0x6AB336)
  static let statusSuccessToast: UIColor = .init(hex: 0x116739)
}

extension UIColor {
  convenience init(hex: Int, alpha: CGFloat = 1.0) {
    let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
    let blue = CGFloat(hex & 0xFF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }

  struct KoyomiColor {
    // Using [iOS 7 colors] as reference.
    // http://ios7colors.com/

    static let lightBlack: UIColor = .init(hex: 0x4A4A4A)
    static let black: UIColor = .init(hex: 0x2B2B2B)
    static let darkBlack: UIColor = .init(hex: 0x1F1F21)
    static let lightGray: UIColor = .init(hex: 0xDBDDDE)
    static let darkGray: UIColor = .init(hex: 0x8E8E93)
    static let lightYellow: UIColor = .init(hex: 0xFFDB4C)
    static let lightPurple: UIColor = .init(hex: 0xC86EDF)
    static let lightGreen: UIColor = .init(hex: 0xA4E786)
    static let lightPink: UIColor = .init(hex: 0xFFD3E0)

    // Using [iOS Human Interface Guidelines] as reference.
    // https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/

    static let red: UIColor = .init(hex: 0xff3b30)
    static let orange: UIColor = .init(hex: 0xff9500)
    static let green: UIColor = .init(hex: 0x4cd964)
    static let blue: UIColor = .init(hex: 0x007aff)
    static let purple: UIColor = .init(hex: 0x5856d6)
    static let yellow: UIColor = .init(hex: 0xffcc00)
    static let tealBlue: UIColor = .init(hex: 0x5ac8fa)
    static let pink: UIColor = .init(hex: 0xff2d55)
  }
}
