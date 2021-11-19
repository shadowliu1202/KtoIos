import UIKit

class ChatLinkTableViewCell: UITableViewCell {
    static let playerLinkIdentifier = "PlayerLinkTableViewCell"
    static let handlerLinkIdentifier = "HandlerLinkTableViewCell"
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var linkTextView: UITextView!
    
    func setHyperLinker(text: String) {
        var urlStr = ""
        var displayText = ""
        if let range = text.range(of: "</p>") {
            displayText = text.replacingCharacters(in: range, with: "\n").removeHtmlTag()
            if let r1 = displayText.range(of: "\n") {
                urlStr = String(displayText[r1.upperBound..<displayText.endIndex])
            }
        }
        
        let attributedString = NSMutableAttributedString(string: displayText)
        let url = URL(string: urlStr)!
        let startIndex = displayText.range(of: "\n")!.upperBound
        let urlRange = startIndex..<displayText.endIndex
        let convertedRange = NSRange(urlRange, in: displayText)
        
        attributedString.setAttributes([.link: url], range: convertedRange)
        
        linkTextView.attributedText = attributedString
        linkTextView.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        linkTextView.font = UIFont(name: "PingFangSC-Regular", size: 14.0)!        
        linkTextView.linkTextAttributes = [
            .foregroundColor: UIColor.red,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
}
