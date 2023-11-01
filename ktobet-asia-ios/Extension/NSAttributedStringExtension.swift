import UIKit

extension NSAttributedString {
  func color(_ color: UIColor, for subString: String? = nil) -> NSAttributedString {
    NSMutableAttributedString(attributedString: self)
      .add(key: .foregroundColor, value: color, for: subString)
  }
  
  func font(_ font: UIFont, for subString: String? = nil) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    let lineHeight = font.lineHeight
    paragraphStyle.minimumLineHeight = lineHeight
          
    return NSMutableAttributedString(attributedString: self)
      .add(key: .font, value: font, for: subString)
      .add(key: .paragraphStyle, value: paragraphStyle, for: subString)
  }
  
  func link(_ url: String, for subString: String? = nil) -> NSAttributedString {
    NSMutableAttributedString(attributedString: self)
      .add(key: .link, value: url, for: subString)
  }
  
  func underline(_ style: NSUnderlineStyle, color: UIColor, for subString: String? = nil) -> NSAttributedString {
    NSMutableAttributedString(attributedString: self)
      .add(key: .underlineStyle, value: style.rawValue, for: subString)
      .add(key: .underlineColor, value: color, for: subString)
  }
  
  func alignment(_ alignment: NSTextAlignment) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = alignment
    
    return NSMutableAttributedString(attributedString: self)
      .add(key: .paragraphStyle, value: paragraphStyle)
  }
}

extension NSAttributedString {
  private func add(key: NSAttributedString.Key, value: Any, for subString: String? = nil) -> NSAttributedString {
    let result: NSMutableAttributedString = .init(attributedString: self)
    let range: NSRange
        
    if let subString {
      range = (string as NSString).range(of: subString)
    }
    else {
      range = NSRange(location: 0, length: string.utf16.count)
    }
        
    result.addAttribute(key, value: value, range: range)
    return result
  }
}
