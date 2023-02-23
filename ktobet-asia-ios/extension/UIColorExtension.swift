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
  static let whitePure: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
  static let whiteE6E6E6: UIColor = #colorLiteral(red: 0.9019607843, green: 0.9019607843, blue: 0.9019607843, alpha: 1)

  static let blackPure: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
  static let black131313: UIColor = #colorLiteral(red: 0.07450980392, green: 0.07450980392, blue: 0.07450980392, alpha: 1)
  static let black1A1A1A: UIColor = #colorLiteral(red: 0.1019607843, green: 0.1019607843, blue: 0.1019607843, alpha: 1)
  static let black2B2B2B: UIColor = #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)

  static let gray131313: UIColor = #colorLiteral(red: 0.07450980392, green: 0.07450980392, blue: 0.07450980392, alpha: 1)
  static let gray202020: UIColor = #colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)
  static let gray2B2B2B: UIColor = #colorLiteral(red: 0.168627451, green: 0.168627451, blue: 0.168627451, alpha: 1)
  static let gray454545: UIColor = #colorLiteral(red: 0.2705882353, green: 0.2705882353, blue: 0.2705882353, alpha: 1)
  static let gray3F3F3F: UIColor = #colorLiteral(red: 0.2470588235, green: 0.2470588235, blue: 0.2470588235, alpha: 1)
  static let gray333333: UIColor = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
  static let gray979797: UIColor = #colorLiteral(red: 0.5921568627, green: 0.5921568627, blue: 0.5921568627, alpha: 1)
  static let gray595959: UIColor = #colorLiteral(red: 0.3490196078, green: 0.3490196078, blue: 0.3490196078, alpha: 1)
  static let gray636366: UIColor = #colorLiteral(red: 0.3882352941, green: 0.3882352941, blue: 0.4, alpha: 1)
  static let gray303030: UIColor = #colorLiteral(red: 0.1882352941, green: 0.1882352941, blue: 0.1882352941, alpha: 1)
  static let gray5C5C5C: UIColor = #colorLiteral(red: 0.3607843137, green: 0.3607843137, blue: 0.3607843137, alpha: 1)
  static let gray3C3E40: UIColor = #colorLiteral(red: 0.2352941176, green: 0.2431372549, blue: 0.2509803922, alpha: 1)
  static let gray9B9B9B: UIColor = #colorLiteral(red: 0.6078431373, green: 0.6078431373, blue: 0.6078431373, alpha: 1)
  static let grayC8D4DE: UIColor = #colorLiteral(red: 0.8232876658, green: 0.8638820052, blue: 0.8960149288, alpha: 1)
  static let grayF2F2F2: UIColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9490196078, alpha: 1)

  static let redF20000: UIColor = #colorLiteral(red: 0.9490196078, green: 0, blue: 0, alpha: 1)
  static let redD90101: UIColor = #colorLiteral(red: 0.8509803922, green: 0.003921568627, blue: 0.003921568627, alpha: 1)

  static let orangeFF8000: UIColor = #colorLiteral(red: 1, green: 0.5019607843, blue: 0, alpha: 1)
  static let orangeFF691D: UIColor = #colorLiteral(red: 1, green: 0.4117647059, blue: 0.1137254902, alpha: 1)

  static let yellowFFD500: UIColor = #colorLiteral(red: 1, green: 0.8352941176, blue: 0, alpha: 1)
  static let yellowEA9E16: UIColor = #colorLiteral(red: 0.9176470588, green: 0.6196078431, blue: 0.0862745098, alpha: 1)

  static let green116739: UIColor = #colorLiteral(red: 0.06666666667, green: 0.4039215686, blue: 0.2235294118, alpha: 1)
  static let green6AB336: UIColor = #colorLiteral(red: 0.4156862745, green: 0.7019607843, blue: 0.2117647059, alpha: 1)
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
