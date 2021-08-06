import UIKit
import RxSwift
import RxCocoa

class WithdrawlEmptyViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    let disposeBag = DisposeBag()
    var bankCardType: BankCardType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self) {
            NavigationManagement.sharedInstance.popToRootViewController()
        }
        
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        switch bankCardType {
        case .crypto:
            titleLabel.text = Localize.string("cps_set_crypto_account")
            descriptionLabel.text = Localize.string("cps_set_crypto_account_hint")
            continueButton.setTitle(Localize.string("common_continue"), for: .normal)
            skipButton.setTitle(Localize.string("common_notset"), for: .normal)
        case .general:
            titleLabel.text = Localize.string("withdrawal_setbankaccount_title")
            descriptionLabel.text = Localize.string("withdrawal_setbankaccount_tips")
            continueButton.setTitle(Localize.string("common_continue"), for: .normal)
            skipButton.setTitle(Localize.string("common_notset"), for: .normal)
        default:
            break
        }
    }
    
    private func dataBinding() {
        continueButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            switch self?.bankCardType {
            case .general:
                self?.performSegue(withIdentifier: AddBankViewController.segueIdentifier, sender: nil)
            case .crypto:
                self?.performSegue(withIdentifier: AddCryptoAccountViewController.segueIdentifier, sender: nil)
            default:
                break
            }
        }).disposed(by: disposeBag)
        skipButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            self?.tapBack()
        }).disposed(by: disposeBag)
    }
    
    func tapBack() {
        NavigationManagement.sharedInstance.popToRootViewController()
    }
}
