import UIKit
import RxSwift

class AboutKTOViewController: APPViewController {
    static let segueIdentifier = "toAboutKTO"
    
    @IBOutlet weak var webLink: UITextView!
    @IBOutlet weak var csLink: UITextView!
    
    private var viewModel = DI.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        setKtoWebLinkTextView()
        setCsLinkTextView()
    }
    
     private func setKtoWebLinkTextView() {
         let link = Localize.string("license_ktoglobal_link")
         let txt = AttribTextHolder(text: link)
             .addAttr((text: link, type: .color, UIColor.redForLightFull))
             .addAttr((text: link, type: .link, link))
         txt.setTo(textView: webLink)
         webLink.textContainerInset = .zero
     }
    
    private func setCsLinkTextView() {
        csLink.textContainerInset = .zero
        viewModel.getCustomerServiceEmail.subscribe(onSuccess: { [unowned self] in
            let csEmail = Localize.string("common_cs_email", "\($0)")
            let txt = AttribTextHolder(text: csEmail)
                .addAttr((text: csEmail, type: .color, UIColor.redForLightFull))
                .addAttr((text: $0, type: .link, URL(string:"mailto:\($0)") as Any))
            txt.setTo(textView: self.csLink)
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }

}
