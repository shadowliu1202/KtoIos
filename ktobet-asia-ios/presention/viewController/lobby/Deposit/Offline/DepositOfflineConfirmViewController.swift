import UIKit
import RxSwift
import SharedBu

class DepositOfflineConfirmViewController: LobbyViewController {
    static let segueIdentifier = "toOfflineConfirmSegue"
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    
    @IBOutlet private weak var bankTitleLabel: UILabel!
    @IBOutlet private weak var bankView: UIView!
    @IBOutlet private weak var bankNameTitleLabel: UILabel!
    @IBOutlet private weak var bankImageView: UIImageView!
    @IBOutlet private weak var bankNameLabel: UILabel!
    @IBOutlet private weak var branchNameTitleLabel: UILabel!
    @IBOutlet private weak var branchNameLabel: UILabel!
    @IBOutlet private weak var userNameTitleLabel: UILabel!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var bankCardNumberTitleLabel: UILabel!
    @IBOutlet private weak var bankCardNumberLabel: UILabel!
    @IBOutlet private weak var validDepositTimeTitleLabel: UILabel!
    @IBOutlet private weak var validDepositTimeLabel: UILabel!
    
    @IBOutlet private weak var tipTitleLabel: UILabel!
    @IBOutlet private weak var remitterView: UIView!
    @IBOutlet private weak var remitterTitleLabel: UILabel!
    @IBOutlet private weak var remitterLabel: UILabel!
    @IBOutlet private weak var amountTitleLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var tipLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!

    @IBOutlet private weak var bankNameCopyButton: UIButton!
    @IBOutlet private weak var branchNameCopyButton: UIButton!
    @IBOutlet private weak var userNameCopyButton: UIButton!
    @IBOutlet private weak var bankCardNumberCopyButton: UIButton!
    
    @IBOutlet private weak var bankImageViewWidthConstraint: NSLayoutConstraint!
    
    private let alert: AlertProtocol = Injectable.resolve(AlertProtocol.self)!
    
    var depositSuccess = false
    
    fileprivate var offlineViewModel = Injectable.resolve(OfflineViewModel.self)!
    fileprivate let timer = CountDownTimer()
    fileprivate var disposeBag = DisposeBag()
    
    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        
        initUI()
        localize()
        bindOfflineViewModel()
    }
    
    @objc func close () {
        Alert.shared.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_offline_termniate"), confirm: {
            Injectable.resetObjectScope(.depositFlow)
            NavigationManagement.sharedInstance.popToRootViewController()
        }, cancel: { })
    }
    
    @IBAction func copyText(_ sender: Any) {
        let button = sender as! UIButton
        switch button.tag {
        case 0:
            UIPasteboard.general.string = bankNameLabel.text
        case 1:
            UIPasteboard.general.string = branchNameLabel.text
        case 2:
            UIPasteboard.general.string = userNameLabel.text
        case 3:
            UIPasteboard.general.string = bankCardNumberLabel.text
        default:
            break
        }
        
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: self.view, statusTip: Localize.string("common_copied"), img: UIImage(named: "Success"))
    }
    
    // MARK: METHOD
    fileprivate func localize() {
        if localStorageRepo.getCultureCode() == SupportLocale.Vietnam.init().cultureCode() {
            remitterView.isHidden = true
            bankImageViewWidthConstraint.isActive = false
            bankImageView.widthAnchor.constraint(equalTo: bankImageView.heightAnchor, multiplier: 3).isActive = true
        }
    }

    fileprivate func initUI() {
        titleLabel.text = Localize.string("deposit_offline_step2_title")
        subTitleLabel.text = Localize.string("deposit_offline_step2_title_tips")
        bankTitleLabel.text = Localize.string("deposit_payee_detail")
        bankView.layer.borderWidth = 1
        bankView.layer.borderColor = UIColor.gray9B9B9B.cgColor
        bankNameTitleLabel.text = Localize.string("deposit_receivebank")
        branchNameTitleLabel.text = Localize.string("deposit_branch")
        userNameTitleLabel.text = Localize.string("deposit_receivename")
        bankCardNumberTitleLabel.text = Localize.string("deposit_receiveaccount")
        validDepositTimeTitleLabel.text = Localize.string("deposit_validdeposittime")
        tipTitleLabel.text = Localize.string("deposit_offline_remitter_title")
        remitterView.layer.borderWidth = 1
        remitterView.layer.borderColor = UIColor.gray9B9B9B.cgColor
        remitterTitleLabel.text = Localize.string("deposit_name")
        amountTitleLabel.text = Localize.string("deposit_custom_cash")
        tipLabel.text = Localize.string("deposit_offline_summary_tip")
        confirmButton.setTitle(Localize.string("common_submit2"), for: .normal)
        let buttons = [bankNameCopyButton, branchNameCopyButton, userNameCopyButton, bankCardNumberCopyButton]
        buttons.forEach {
            $0?.layer.borderColor = UIColor.gray9B9B9B.cgColor
            $0?.layer.borderWidth = 1
            $0?.setTitle(Localize.string("common_copy"), for: .normal)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }
    
    fileprivate func bindOfflineViewModel() {
        confirmButton.rx.tap.bind(to: offlineViewModel.input.depositTrigger).disposed(by: disposeBag)
        offlineViewModel.output.deposit.drive(onNext: { [weak self] isSuccess in
            self?.depositSuccess = isSuccess
            Injectable.resetObjectScope(.depositFlow)
        }).disposed(by: disposeBag)
        offlineViewModel.output.selectPaymentGatewayIcon.drive(bankImageView.rx.image).disposed(by: disposeBag)
        offlineViewModel.output.memo.drive(onNext: { [weak self] memo in
            self?.branchNameLabel.text = memo.beneficiary.branch
            self?.userNameLabel.text = memo.beneficiary.account.accountName
            self?.bankCardNumberLabel.text = memo.beneficiary.account.accountNumber
            self?.remitterLabel.text = memo.remitter.name
            var amountStr = memo.remittance.formatString(sign: .signed_)
            amountStr.removeFirst()
            let attributedString = NSMutableAttributedString(string: amountStr, attributes: [
                .font: UIFont(name: "PingFangSC-Semibold", size: 24.0)!,
                .foregroundColor: UIColor.whitePure
            ])
            
            attributedString.addAttribute(.foregroundColor, value: UIColor.orangeFF8000, range: NSRange(location: amountStr.count - 2, length: 2))
            self?.amountLabel.attributedText = attributedString
            self?.startExpireTimer(expiredHour: memo.expiredHour)
        }).disposed(by: disposeBag)
        
        offlineViewModel.output.selectPaymentGateway.drive(onNext: { [weak self] paymentGateway in
            self?.bankNameLabel.text = paymentGateway.name
        }).disposed(by: disposeBag)
        
        offlineViewModel.errors().subscribe(onNext: {[weak self] error in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func startExpireTimer(expiredHour: Int64) {
        timer.start(timeInterval: 1, duration: TimeInterval(expiredHour * 60 * 60)) { [weak self] (index, countDownSecond, finish) in
            let hh = countDownSecond / 3600
            let mm = countDownSecond % 3600 / 60
            let ss = countDownSecond % 60
            if hh < 1 {
                self?.validDepositTimeLabel.text = String(format: "%02d:%02d", mm, ss)
            } else {
                self?.validDepositTimeLabel.text = String(format: "%02d:%02d:%02d", hh, mm, ss)
            }
        }
    }
    
    override func handleErrors(_ error: Error) {
        if error is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func notifyTryLaterAndPopBack() {
        alert.show(nil, Localize.string("deposit_notify_request_later"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
