import UIKit

class AttribTextHolder {
    enum AttrType {
        case link
        case color
        case font
        case center
    }
    
    let originalText: String
    var attributes: [(text: String, type: AttrType, value: Any)]
    
    
    init(text: String, attrs: [(text: String, type: AttrType, value: Any)] = []) {
        originalText = text
        attributes = attrs
    }
    
    func addAttr(_ attr: (text: String, type: AttrType, value: Any)) -> AttribTextHolder {
        attributes.append(attr)
        return self
    }
    
    func setTo(textView: UITextView) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        
        let baseFontAttribute = [NSAttributedString.Key.font : UIFont(name: "PingFangSC-Semibold", size: 16)]
        let attributedOriginalText = NSMutableAttributedString(string: originalText, attributes: baseFontAttribute as [NSAttributedString.Key : Any])
        
        for item in attributes {
            let arange = attributedOriginalText.mutableString.range(of: item.text)
            switch item.type {
            case .link:
                attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: item.value, range: arange)
            case .color:
                var color = UIColor.black
                if let c = item.value as? UIColor { color = c }
                attributedOriginalText.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: arange)
            case .font:
                let boldFontAttribute = [NSAttributedString.Key.font : item.value]
                attributedOriginalText.addAttributes(boldFontAttribute, range: NSRange(originalText.range(of: item.text) ?? originalText.startIndex..<originalText.endIndex, in: originalText))
            case .center:
                style.alignment = .center
            }
        }
        
        let fullRange = NSMakeRange(0, attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        
        textView.linkTextAttributes = [
            kCTForegroundColorAttributeName: UIColor.blue,
            kCTUnderlineStyleAttributeName: NSUnderlineStyle.single.rawValue,
            ] as [NSAttributedString.Key : Any]
        
        textView.attributedText = attributedOriginalText
    }
}
