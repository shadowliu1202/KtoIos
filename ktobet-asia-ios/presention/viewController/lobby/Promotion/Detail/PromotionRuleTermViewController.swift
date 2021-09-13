import UIKit

class PromotionRuleTermViewController: UIViewController {
    static let segueIdentifier = "toPromotionRuleTerm"
    @IBOutlet weak var textView: UITextView!
    
    var privacyTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close)
        textView.delegate = self
        
        privacyTitle = Localize.string("license_promotion_terms")
        //TODO: get from API
        let RuleTermTxt =
            privacyTitle + "\n\n" +
            Localize.string("license_promotion_warning_1") + "\n\n" +
            Localize.string("license_promotion_warning_2") + "\n\n" +
            Localize.string("license_promotion_warning_3") + "\n\n" +
            Localize.string("license_promotion_warning_4") + "\n\n" +
            Localize.string("license_promotion_warning_5") + "\n\n" +
            Localize.string("license_promotion_warning_6") + "\n\n" +
            Localize.string("license_promotion_warning_7") + "\n\n" +
            Localize.string("license_promotion_warning_8") + "\n\n" +
            Localize.string("license_promotion_warning_9") + "\n\n" +
            Localize.string("license_promotion_warning_10") + "\n\n" +
            Localize.string("license_promotion_warning_11") + "\n\n" +
            String(Localize.string("license_promotion_warning_12").dropLast()) + Localize.string("license_promotion_privacyppolicy") + "。 \n\n" +
            Localize.string("license_promotion_warning_13") + "\n\n" +
            Localize.string("license_promotion_warning_14")
        
        textView.textContainerInset = UIEdgeInsets(top: 30, left: 30, bottom: 96, right: 30)
        addHyperLinksToText(originalText: RuleTermTxt, hyperLinks: [Localize.string("license_promotion_privacyppolicy"): "someUrl1"])
        textView.sizeToFit()
    }
    
    private func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        var attributedOriginalText = NSMutableAttributedString(string: originalText)
        for (hyperLink, urlString) in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
        }
        
        setTextFont(attributedOriginalText: &attributedOriginalText)
        
        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.red,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        textView.attributedText = attributedOriginalText
    }
    
    private func setTextFont(attributedOriginalText: inout NSMutableAttributedString) {
        let titleRange = NSRange(location: 0, length: privacyTitle.count)
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.init(name: "PingFangSC-Regular", size: 14)!, range: fullRange)
        attributedOriginalText.addAttribute(NSAttributedString.Key.font, value: UIFont.init(name: "PingFangSC-Medium", size: 16)!, range: titleRange)
    }
}

extension PromotionRuleTermViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if (URL.absoluteString == "someUrl1") {
            if let termsOfServiceViewController = UIStoryboard(name: "Signup", bundle: nil).instantiateViewController(withIdentifier: "TermsOfServiceViewController") as? TermsOfServiceViewController {
                termsOfServiceViewController.termsType = .promotionSecurityPrivacy
                NavigationManagement.sharedInstance.pushViewController(vc: termsOfServiceViewController)
            }
        }
        
        return false
    }
}
