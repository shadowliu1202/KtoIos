import UIKit

class AttributedText: NSAttributedString {
  convenience init(text: String) {
    let attributedString = NSAttributedString(string: text).font(UIFont(name: "PingFangSC-Semibold", size: 16)!)
    self.init(attributedString: attributedString)
  }
}
