import UIKit
import RxSwift
import SharedBu

class WithdrawalAccountDetailViewController: UIViewController {
    static let segueIdentifier = "toAccountDetail"
    
    fileprivate var viewModel = DI.resolve(WithdrawlLandingViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    var account: WithdrawalAccount?
    @IBOutlet weak var verifyStatusLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var bankNameLabel: UILabel!
    @IBOutlet weak var branchNameLabel: UILabel!
    @IBOutlet weak var provinceLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        verifyStatusLabel.text = account?.verifyStatusLocalize
        userNameLabel.text = account?.accountName
        bankNameLabel.text = account?.bankName
        branchNameLabel.text = account?.branch
        provinceLabel.text = account?.location
        countryLabel.text = account?.city
        accountNumberLabel.text = account?.accountNumber.value
        if account?.verifyStatus == .verifying {
            submitButton.isHidden = true
        }
    }
    
    private func dataBinding() {
        submitButton.rx.touchUpInside.bind { [weak self] (_) in
            if let `self` = self, let id = self.account?.playerBankCardId {
                Alert.show(Localize.string("common_confirm_delete"),
                           Localize.string("withdrawal_bank_card_deleting"),
                           confirm: { self.deleteAccount(id) },
                           confirmText: Localize.string("common_yes"),
                           cancel: {},
                           cancelText: Localize.string("common_no"))
            }
        }.disposed(by: disposeBag)
    }
    
    private func deleteAccount(_ playerBankCardId: String) {
        viewModel.deleteAccount(playerBankCardId).subscribe(onCompleted: { [weak self] in
            self?.popThenToast()
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
    
    private func popThenToast() {
        NavigationManagement.sharedInstance.popViewController({
            if let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: topVc.view.frame.width, height: 48))
                toastView.show(on: topVc.view, statusTip: Localize.string("withdrawal_account_deleted"), img: UIImage(named: "Success"))
            }
        })
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
