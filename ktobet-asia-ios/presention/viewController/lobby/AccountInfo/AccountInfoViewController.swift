import UIKit
import RxSwift
import RxCocoa
import SharedBu

class AccountInfoViewController: APPViewController {

    @IBOutlet weak var affiliateLabel: UILabel!
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: nil)
        
        viewModel.isAffiliateMember.subscribe(onSuccess: { [weak self] in
            guard let `self` = self else {return}
            self.affiliateLabel.isHidden = !$0
            let gesture =  UITapGestureRecognizer(target: self, action: #selector(self.touchAction(_:)))
            self.affiliateLabel.isUserInteractionEnabled = true
            self.affiliateLabel.addGestureRecognizer(gesture)
        }).disposed(by: disposeBag)
    }
    
    @objc private func touchAction(_ sender: UITapGestureRecognizer) {
        if UIApplication.shared.canOpenURL(Configuration.affiliateUrl) {
            UIApplication.shared.open(Configuration.affiliateUrl)
        }
    }
}
