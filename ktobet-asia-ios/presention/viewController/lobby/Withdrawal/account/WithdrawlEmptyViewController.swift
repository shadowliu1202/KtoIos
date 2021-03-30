import UIKit
import RxSwift
import RxCocoa

class WithdrawlEmptyViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        titleLabel.text = Localize.string("withdrawal_setbankaccount_title")
        descriptionLabel.text = Localize.string("withdrawal_setbankaccount_tips")
        continueButton.setTitle(Localize.string("common_continue"), for: .normal)
        skipButton.setTitle(Localize.string("common_notset"), for: .normal)
    }

    
    private func dataBinding() {
        continueButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            self?.performSegue(withIdentifier: AddBankViewController.segueIdentifier, sender: nil)
        }).disposed(by: disposeBag)
        skipButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            self?.tapBack()
        }).disposed(by: disposeBag)
    }
    
    func tapBack() {
        NavigationManagement.sharedInstance.popViewController()
    }
}
