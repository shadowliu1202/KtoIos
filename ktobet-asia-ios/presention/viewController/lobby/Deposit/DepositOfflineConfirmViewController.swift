import UIKit
import RxSwift
import SharedBu

class DepositOfflineConfirmViewController: UIViewController {
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

    var depositRequest: DepositRequest_!
    var selectedReceiveBank: OfflineBank!
    var depositSuccess = false
    
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate let timer = CountDownTimer()
    fileprivate var disposeBag = DisposeBag()

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        
        initUI()
        dataBinding()
        startExpireTimer()
    }
    
    @objc func close () {
        Alert.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_offline_termniate"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: {})
    }
    
    // MARK: BUTTON ACTION
    @IBAction func confirm(_ sender: Any) {
        self.viewModel.depositOffline(depositRequest: depositRequest, depositTypeId: 0).subscribe { (orderNumber) in
            self.depositSuccess = true
            self.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
        } onError: { (error) in
            self.depositSuccess = false
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
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
    fileprivate func initUI() {
        titleLabel.text = Localize.string("deposit_offline_step2_title")
        subTitleLabel.text = Localize.string("deposit_offline_step2_title_tips")
        bankTitleLabel.text = Localize.string("deposit_payee_detail")
        bankView.layer.borderWidth = 1
        bankView.layer.borderColor = UIColor.textPrimaryDustyGray.cgColor
        bankNameTitleLabel.text = Localize.string("deposit_receivebank")
        branchNameTitleLabel.text = Localize.string("deposit_branch")
        userNameTitleLabel.text = Localize.string("deposit_receivename")
        bankCardNumberTitleLabel.text = Localize.string("deposit_receiveaccount")
        validDepositTimeTitleLabel.text = Localize.string("deposit_validdeposittime")
        tipTitleLabel.text = Localize.string("deposit_offline_remitter_title")
        remitterView.layer.borderWidth = 1
        remitterView.layer.borderColor = UIColor.textPrimaryDustyGray.cgColor
        remitterTitleLabel.text = Localize.string("deposit_name")
        amountTitleLabel.text = Localize.string("deposit_custom_cash")
        tipLabel.text = Localize.string("deposit_offline_summary_tip")
        confirmButton.setTitle(Localize.string("common_submit2"), for: .normal)
        bankImageView.image = UIImage(named: self.viewModel.getBankIcon(selectedReceiveBank!.bankId))
        let buttons = [bankNameCopyButton, branchNameCopyButton, userNameCopyButton, bankCardNumberCopyButton]
        buttons.forEach{
            $0?.layer.borderColor = UIColor.textPrimaryDustyGray.cgColor
            $0?.layer.borderWidth = 1
            $0?.setTitle(Localize.string("common_copy"), for: .normal)
        }
    }

    fileprivate func dataBinding() {
        bankNameLabel.text = selectedReceiveBank?.name ?? ""
        userNameLabel.text = selectedReceiveBank.owner.name
        branchNameLabel.text = selectedReceiveBank.branch
        bankCardNumberLabel.text = selectedReceiveBank.owner.accountNumber
        remitterLabel.text = depositRequest.remitter.name
        var amountStr = depositRequest.amount.formatString(sign: .signed_)
        amountStr.removeFirst()
        let attributedString = NSMutableAttributedString(string: amountStr, attributes: [
                .font: UIFont(name: "PingFangSC-Semibold", size: 24.0)!,
                .foregroundColor: UIColor.whiteFull
        ])

        attributedString.addAttribute(.foregroundColor, value: UIColor.orangeFull, range: NSRange(location: amountStr.count - 2, length: 2))
        amountLabel.attributedText = attributedString
    }

    fileprivate func startExpireTimer() {
        timer.start(timeInterval: 1, duration: 7200) { [weak self] (index, countDownSecond, finish) in
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
}
