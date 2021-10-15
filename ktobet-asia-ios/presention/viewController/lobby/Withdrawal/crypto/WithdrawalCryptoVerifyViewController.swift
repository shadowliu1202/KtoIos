import UIKit
import RxSwift
import SharedBu

class WithdrawalCryptoVerifyViewController: UIViewController {
    static let segueIdentifier = "toCryptoVerify"
    
    @IBOutlet private weak var btnPhone: UIButton!
    @IBOutlet private weak var btnEmail: UIButton!
    @IBOutlet private weak var btnSubmit: UIButton!
    @IBOutlet private weak var contentLabel : UILabel!
    @IBOutlet private weak var viewOtpServiceDown : UIView!
    @IBOutlet private weak var viewInputView : UIView!
    @IBOutlet private weak var constraintResetErrorView: NSLayoutConstraint!
    @IBOutlet private weak var constraintResetErrorViewPadding: NSLayoutConstraint!
    
    let viewModel = DI.resolve(CryptoVerifyViewModel.self)!
    let disposeBag = DisposeBag()
    
    var cryptoBankCard: CryptoBankCard?
    var playerCryptoBankCardId: String?
    
    private var isFirstTimeEnter = true
    private var phone: String = ""
    private var email: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        
        btnPhone.setTitle(Localize.string("common_mobile"), for: .normal)
        btnEmail.setTitle(Localize.string("common_email"), for: .normal)
        for button in [btnEmail, btnPhone]{
            let selectedColor = UIColor.backgroundTabsGray
            let unSelectedColor = UIColor.clear
            button?.setBackgroundImage(UIImage(color: selectedColor), for: .selected)
            button?.setBackgroundImage(UIImage(color: unSelectedColor), for: .normal)
            button?.layer.cornerRadius = 8
            button?.layer.masksToBounds = true
        }
        
        viewModel.otpValid().subscribe(onNext: {[weak self] status in
            guard let self = self else { return }
            if status == .errOtpServiceDown {
                Alert.show(Localize.string("common_error"), Localize.string("cps_otp_service_down"), confirm: {
                    NavigationManagement.sharedInstance.popViewController()
                }, cancel: nil)
            } else if status == .errSMSOtpInactive || status == .errEmailOtpInactive {
                self.viewOtpServiceDown.isHidden = false
                self.viewInputView.isHidden = true
            } else {
                self.viewOtpServiceDown.isHidden = true
                self.viewInputView.isHidden = false
            }
        }).disposed(by: disposeBag)
        
        viewModel.phone.subscribe { (phone) in
            if let phone = phone, !phone.isEmpty {
                self.phone = Localize.string("common_otp_hint") + "\n" + phone
            } else {
                self.phone = Localize.string("common_not_set_mobile")
            }
            
            self.contentLabel.text = self.phone
            self.btnSubmit.isHidden = self.phone == Localize.string("common_not_set_mobile")
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: self.disposeBag)
        
        viewModel.email.subscribe { (email) in
            if let email = email, !email.isEmpty {
                self.email = Localize.string("common_otp_hint") + "\n" + email
            } else {
                self.email = Localize.string("common_not_set_email")
            }
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: self.disposeBag)
        
        btnEmail.rx.tap.subscribe {[weak self] _ in
            guard let self = self else { return }
            self.btnPhone.isSelected = false
            self.btnEmail.isSelected = true
            self.viewModel.relayAccountType.accept(.email)
            self.contentLabel.text = self.email
            self.btnSubmit.isHidden = self.email == Localize.string("common_not_set_email")
        }.disposed(by: disposeBag)
        
        btnPhone.rx.tap.subscribe {[weak self] _ in
            guard let self = self else { return }
            self.btnEmail.isSelected = false
            self.btnPhone.isSelected = true
            self.viewModel.relayAccountType.accept(.phone)
            self.contentLabel.text = self.phone
            self.btnSubmit.isHidden = self.phone == Localize.string("common_not_set_mobile")
        }.disposed(by: disposeBag)
        
        btnSubmit.rx.tap.subscribe {[weak self] _ in
            guard let self = self else { return }
            guard let bankCardId = self.cryptoBankCard?.bankCard.id_ ?? self.playerCryptoBankCardId else { return }
            self.viewModel.verify(playerCryptoBankCardId: bankCardId).subscribe(onCompleted: {[weak self] in
                self?.performSegue(withIdentifier: WithdrawalOTPVerifyViewController.segueIdentifier, sender: nil)
            }, onError: {[weak self] (error) in
                self?.showToastAlertFailed()
            }).disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)
    }
    
    @objc func close() {
        self.performSegue(withIdentifier: WithdrawlLandingViewController.unwindSegue, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalOTPVerifyViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalOTPVerifyViewController {
                dest.viewModel = viewModel
            }
        }
    }
    
    private func showToastAlertFailed() {
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: self.view, statusTip: Localize.string("common_otp_send_fail"), img: UIImage(named: "Failed"))
    }
}
