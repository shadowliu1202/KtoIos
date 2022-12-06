import UIKit
import RxSwift


class PromotionRuleTermViewController: LobbyViewController {
    static let segueIdentifier = "toPromotionRuleTerm"
    @IBOutlet weak var textView: UITextView!
    
    var privacyTitle = ""
    
    private var viewModel = Injectable.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close)
        textView.delegate = self
        
        var ruleTermTxt = ""
        viewModel.getPromotionPolicy().subscribe {[weak self] p in
            self?.privacyTitle = p.title
            ruleTermTxt = p.title  + "\n\n"
            p.content.forEach{ ruleTermTxt += ($0 + "\n\n").replacingOccurrences(of: "{policy}", with: p.linkTitle) }
            self?.addHyperLinksToText(originalText: ruleTermTxt, hyperLinks: [p.linkTitle: "someUrl1"])
        } onError: {[weak self] error in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
        
        textView.textContainerInset = UIEdgeInsets(top: 30, left: 30, bottom: 96, right: 30)
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
            NSAttributedString.Key.foregroundColor: UIColor.redF20000,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        textView.attributedText = attributedOriginalText
        textView.sizeToFit()
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
            NavigationManagement.sharedInstance.pushViewController(
                vc: TermsOfServiceViewController.instantiate(SecurityPrivacyTerms())
            )
        }
        
        return false
    }
}
