import sharedbu
import UIKit

extension UILabel {
    @IBInspectable public var localizeText: String? {
        get { text }
        set { text = newValue == nil ? nil : Localize.string(newValue!) }
    }

    func highlight(text: String?, font: UIFont? = nil, color: UIColor? = nil) {
        guard let fullText = self.text, let target = text else {
            return
        }

        let attribText = NSMutableAttributedString(string: fullText)
        let range: NSRange = attribText.mutableString.range(of: target, options: .caseInsensitive)

        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font {
            attributes[.font] = font
        }
        if let color {
            attributes[.backgroundColor] = color
        }
        attribText.addAttributes(attributes, range: range)
        self.attributedText = attribText
    }

    func retrieveTextHeight() -> CGFloat {
        let attributedText = NSAttributedString(string: self.text!, attributes: [NSAttributedString.Key.font: self.font!])
        let rect = attributedText.boundingRect(
            with: CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil)
        return ceil(rect.size.height)
    }

    var isTruncated: Bool {
        frame.width < intrinsicContentSize.width
    }

    func countLines() -> Int {
        self.layoutIfNeeded()
        let myText = self.text! as NSString
        let attributes = [NSAttributedString.Key.font: self.font]

        let labelSize = myText.boundingRect(
            with: CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes as [NSAttributedString.Key: Any],
            context: nil)
        return Int(ceil(CGFloat(labelSize.height) / self.font.lineHeight))
    }

    func localizedFont(by playerLocale: SupportLocale, weight: KTOFontWeight, size: CGFloat) {
        font = UIFont(name: weight.fontString(playerLocale), size: size)
    }
}

extension UIFont {
    var bold: UIFont {
        with(.traitBold)
    }

    var italic: UIFont {
        with(.traitItalic)
    }

    var boldItalic: UIFont {
        with([.traitBold, .traitItalic])
    }

    func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard
            let descriptor = self.fontDescriptor
                .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits))
        else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }

    func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard
            let descriptor = self.fontDescriptor
                .withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits)))
        else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(
            for: locationOfTouchInTextContainer,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil)

        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
