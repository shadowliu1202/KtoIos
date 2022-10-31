import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SetIdentityViewController: LobbyViewController {
    @IBOutlet private weak var inputIdentity: InputText!
    @IBOutlet private weak var stepTitle: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var settingButton: UIButton!
    @IBOutlet private weak var labResetTypeTip: UILabel!
    @IBOutlet private weak var constraintErrorHeight: NSLayoutConstraint!
    @IBOutlet private weak var errorLabel: UILabel!
    
    var delegate: SetIdentityDelegate!
    
    private var viewModel = DI.resolve(CommonOtpViewModel.self)!
    private var disposeBag = DisposeBag()
    private let countDownTimer = CountDownTimer()
    private var countDownSecond = 0
    
    private let RetryLimit = 11
    private let LockSeconds: Double = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavigateItem()
        initialize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputIdentity.showKeyboard()
    }
    
    private func initNavigateItem() {
        if delegate.setIdentityArgs.barItemType == .back {
            NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        } else if delegate.setIdentityArgs.barItemType == .close {
            NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        }
    }
    
    private func initialize() {
        stepTitle.text = delegate.setIdentityArgs.stepTitle
        titleLabel.text = delegate.setIdentityArgs.title
        descriptionLabel.text = delegate.setIdentityArgs.description
        settingButton.isValid = false
        inputIdentity.setKeyboardType(delegate.setIdentityArgs.keyboardType)
        inputIdentity.setTitle(delegate.setIdentityArgs.inputTitle)
        if delegate.setIdentityArgs.accountType == .phone {
            inputIdentity.setSubTitle("+\(viewModel.locale.cellPhoneNumberFormat().areaCode())")
        }
        
        if delegate.setIdentityArgs.accountType == .email {
            inputIdentity.maxLength = Account.Email.companion.MAX_LENGTH
        }
        
        inputIdentity.textContent.rx
            .controlEvent(.editingChanged)
            .withLatestFrom(inputIdentity.textContent.rx.text.orEmpty)
            .subscribe(onNext: { [unowned self] text in
                self.clearError()
                self.showErrorTip(identity: text)
            }).disposed(by: disposeBag)
        
        settingButton.rx.throttledTap
            .withUnretained(self)
            .flatMap({ owner, _ in
                owner.delegate.modifyIdentity(identity: owner.inputIdentity.textContent.text!)
                    .do(onCompleted: { [weak self] in
                        guard let self = self else { return }
                        
                        self.viewModel.otpRetryCount = 0
                        self.delegate.navigateToOtpSent(identity: self.inputIdentity.textContent.text!)
                    })
                    .asObservable()
            })
            .subscribe()
            .disposed(by: disposeBag)

        delegate.handleErrors().subscribe(onNext: { [unowned self] error in
            if error.isUnauthorized() {
                SideBarViewController.showAuthorizationPage()
            } else {
                viewModel.otpRetryCount += 1
                switch error {
                case is KtoOtpMaintenance:
                    self.navToServiceUnavailablePage()
                case is UnhandledException:
                    self.displayError(self.delegate.setIdentityArgs.invalidIdentityError)
                case is KtoOldProfileValidateFail:
                    self.navigateToErrorPage()
                case is KtoPlayerOverOtpDailySendLimit:
                    self.alertExceedResendLimit()
                default:
                    self.handleErrors(error)
                }
                self.checkLimitAndLock(count: viewModel.otpRetryCount)
            }
        }).disposed(by: disposeBag)
    }
    
    private func showErrorTip(identity: String) {
        let status = delegate.setIdentityArgs.accountType == .email ? emailValid(identity) : mobileValid(identity)
        var message = ""
        if status == .errEmailFormat {
            message = self.delegate.setIdentityArgs.inputFormatError
        } else if status == .empty {
            message = Localize.string("common_field_must_fill")
        } else if status == .errPhoneFormat {
            message = Localize.string("common_error_mobile_format")
        }
        
        self.labResetTypeTip.text = message
        self.settingButton.isValid = status == .valid && self.countDownSecond == 0
    }
    
    private func emailValid(_ text: String) -> UserInfoStatus {
        let valid = Account.Email(email: text).isValid()
        if valid {
            return .valid
        } else if text.count == 0 {
            return .empty
        } else {
            return .errEmailFormat
        }
    }
    
    private func mobileValid(_ text: String) -> UserInfoStatus {
        let valid = Account.Phone(phone: text, locale: viewModel.locale).isValid()
        if valid {
            return .valid
        } else if text.count == 0 {
            return .empty
        } else {
            return .errPhoneFormat
        }
    }
    
    private func checkLimitAndLock(count: Int) {
        if (count >= RetryLimit) {
            settingButton.isValid = false
            displayError(Localize.string("profile_bind_identity_locked"))
            setCountDownTimer()
        } else {
            settingButton.isValid = true
        }
    }
    
    private func setCountDownTimer() {
        countDownTimer.start(timeInterval: 1, duration: LockSeconds) { [weak self] (index, countDownSecond, finish) in
            self?.countDownSecond = countDownSecond
            self?.settingButton.setTitle(Localize.string("common_get_code_countdown", "\(countDownSecond)"), for: .normal)
            if countDownSecond == 0 {
                self?.settingButton.isValid = true
                self?.settingButton.setTitle(Localize.string("common_get_code", "\(countDownSecond)"), for: .normal)
            }
        }
    }
    
    private func displayError(_ content: String) {
        errorLabel.text = content
        constraintErrorHeight.constant = 44
    }
    
    private func clearError() {
        errorLabel.text = ""
        constraintErrorHeight.constant = 0
    }
    
    private func alertExceedResendLimit() {
        Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("profile_otp_exceed_otp_limit"), confirm: { [weak self] in
            self?.navigateToErrorPage()
        }, cancel: nil)
    }
    
    private func navToServiceUnavailablePage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.setIdentityArgs.maintenanceErrorType
        NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
    }
    
    private func navigateToErrorPage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.setIdentityArgs.failedType
        NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
    }
    
    @objc func close() {
        Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

protocol SetIdentityDelegate {
    var setIdentityArgs: SetIdentityArgs { get }
    var viewModel: ModifyProfileViewModel { get }

    func modifyIdentity(identity: String) -> Completable
    func handleErrors() -> Observable<Error>
    func navigateToOtpSent(identity: String)
}

struct SetIdentityArgs {
    fileprivate(set) var keyboardType: UIKeyboardType
    fileprivate(set) var failedType: CommonFailedTypeProtocol
    fileprivate(set) var stepTitle: String
    fileprivate(set) var title: String
    fileprivate(set) var description: String
    fileprivate(set) var maintenanceErrorType: CommonFailedTypeProtocol
    fileprivate(set) var inputTitle: String
    fileprivate(set) var inputFormatError: String
    fileprivate(set) var invalidIdentityError: String
    fileprivate(set) var barItemType: BarItemType
    fileprivate(set) var accountType: AccountType
}

protocol ISetIdentityBuilder {
    func build() -> SetIdentityArgs
}

class SetIdentityBuilder: ISetIdentityBuilder {
    fileprivate(set) var keyboardType: UIKeyboardType
    fileprivate(set) var failedType: CommonFailedTypeProtocol
    fileprivate(set) var stepTitle: String
    fileprivate(set) var title: String
    fileprivate(set) var description: String
    fileprivate(set) var maintenanceErrorType: CommonFailedTypeProtocol
    fileprivate(set) var inputTitle: String
    fileprivate(set) var inputFormatError: String
    fileprivate(set) var invalidIdentityError: String
    fileprivate(set) var barItemType: BarItemType
    fileprivate(set) var accountType: AccountType
    
    fileprivate init(keyboardType: UIKeyboardType = .emailAddress,
                     failedType: CommonFailedTypeProtocol = CommonFailedType(),
                     stepTitle: String = "",
                     title: String = "",
                     description: String = "",
                     maintenanceErrorType: CommonFailedTypeProtocol,
                     inputTitle: String = "",
                     inputFormatError: String = "",
                     invalidIdentityError: String = "",
                     barItemType: BarItemType,
                     accountType: AccountType) {
        self.keyboardType = keyboardType
        self.failedType = failedType
        self.stepTitle = stepTitle
        self.title = title
        self.description = description
        self.maintenanceErrorType = maintenanceErrorType
        self.inputTitle = inputTitle
        self.inputFormatError = inputFormatError
        self.invalidIdentityError = invalidIdentityError
        self.barItemType = barItemType
        self.accountType = accountType
    }
    
    func build() -> SetIdentityArgs {
        SetIdentityArgs(keyboardType: keyboardType,
                        failedType: failedType,
                        stepTitle: stepTitle,
                        title: title,
                        description: description,
                        maintenanceErrorType: maintenanceErrorType,
                        inputTitle: inputTitle,
                        inputFormatError: inputFormatError,
                        invalidIdentityError: invalidIdentityError,
                        barItemType: barItemType,
                        accountType: accountType)
    }
}

class SetIdentityFactory {
    static func create(mode: ModifyMode, accountType: AccountType) -> SetIdentityArgs {
        SetIdentityFactory().create(mode: mode, accountType: accountType)
    }
    
    private func create(mode: ModifyMode, accountType: AccountType) -> SetIdentityArgs {
        switch mode {
        case .new:
            switch accountType {
            case .phone:
                return profileNoExistMobileArgs()
            case .email:
                return profileNoExistEmailArgs()
            }
        case .oldModify:
            switch accountType {
            case .phone:
                return profileExistMobileArgs()
            case .email:
                return profileExistEmailArgs()
            }
        }
    }
    
    private func profileExistEmailArgs() -> SetIdentityArgs {
        SetIdentityBuilder(failedType: ProfileEmailFailedType(title: Localize.string("profile_identity_email_modify_fail")),
                           stepTitle: Localize.string("profile_identity_email_step3"),
                           title: Localize.string("profile_identity_email_step3_title"),
                           description: Localize.string("profile_identity_email_step3_description"),
                           maintenanceErrorType: ProfileEmailFailedType(title: Localize.string("profile_email_inactive")),
                           inputTitle: Localize.string("common_email"),
                           inputFormatError: Localize.string("common_error_email_format"),
                           invalidIdentityError: Localize.string("common_error_email_verify"),
                           barItemType: .close,
                           accountType: .email).build()
    }
    
    private func profileExistMobileArgs() -> SetIdentityArgs {
        SetIdentityBuilder(keyboardType: .phonePad,
                           failedType: ProfileEmailFailedType(title: Localize.string("profile_identity_mobile_modify_fail")),
                           stepTitle: Localize.string("profile_identity_mobile_step3"),
                           title: Localize.string("profile_identity_mobile_step3_title"),
                           description: Localize.string("profile_identity_mobile_step3_description"),
                           maintenanceErrorType: ProfileMobileFailedType(title: Localize.string("profile_sms_inactive")),
                           inputTitle: Localize.string("common_mobile"),
                           inputFormatError: Localize.string("common_error_mobile_format"),
                           invalidIdentityError: Localize.string("common_error_phone_verify"),
                           barItemType: .close,
                           accountType: .phone).build()
    }
    
    private func profileNoExistEmailArgs() -> SetIdentityArgs {
        SetIdentityBuilder(failedType: ProfileEmailFailedType(title: Localize.string("profile_identity_email_modify_fail")),
                           stepTitle: Localize.string("profile_identity_email_step3_title"),
                           title: Localize.string("profile_identity_email_step3_title"),
                           description: Localize.string("profile_identity_email_step3_description"),
                           maintenanceErrorType: ProfileEmailFailedType(title: Localize.string("profile_email_inactive")),
                           inputTitle: Localize.string("common_email"),
                           inputFormatError: Localize.string("common_error_email_format"),
                           invalidIdentityError: Localize.string("common_error_email_verify"),
                           barItemType: .back,
                           accountType: .email).build()
    }
    
    private func profileNoExistMobileArgs() -> SetIdentityArgs {
        SetIdentityBuilder(keyboardType: .phonePad,
                           failedType: ProfileEmailFailedType(title: Localize.string("profile_identity_mobile_modify_fail")),
                           title: Localize.string("profile_identity_mobile_step3_title"),
                           description: Localize.string("profile_new_mobile_description"),
                           maintenanceErrorType: ProfileMobileFailedType(title: Localize.string("profile_sms_inactive")),
                           inputTitle: Localize.string("common_mobile"),
                           inputFormatError: Localize.string("common_error_mobile_format"),
                           invalidIdentityError: Localize.string("common_error_phone_verify"),
                           barItemType: .back,
                           accountType: .phone).build()
    }
}

enum ModifyMode {
    case oldModify
    case new
}
