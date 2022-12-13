import UIKit
import RxSwift
import SharedBu
import RxCocoa

class DepositGatewayViewController: LobbyViewController {
    static let segueIdentifier = "toOfflineSegue"
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var selectDepositBankLabel: UILabel!
    @IBOutlet private weak var depositTableView: UITableView!
    @IBOutlet private weak var myDepositInfo: UILabel!
    @IBOutlet private weak var remitterBankTextField: DropDownInputText!
    @IBOutlet private weak var remitterNameTextField: InputText!
    @IBOutlet private weak var remitterBankCardNumberTextField: InputText!
    @IBOutlet private weak var remitterAmountTextField: InputText!
    @IBOutlet private weak var remitterAmountDropDown: DropDownInputText!
    @IBOutlet private weak var depositAmountHintLabel: UILabel!
    @IBOutlet private weak var remitterHintLabel: UILabel!
    @IBOutlet private weak var depositConfirmButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var constraintBankTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintremitterBankTextFieldHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintremitterBankTextFieldTop: NSLayoutConstraint!
    @IBOutlet private weak var remitterBankErrorLabel: UILabel!
    @IBOutlet private weak var remitterNameErrorLabel: UILabel!
    @IBOutlet private weak var remitterBankCardNumberErrorLabel: UILabel!
    @IBOutlet private weak var remitterAmountErrorLabel: UILabel!
    @IBOutlet private weak var withdrawalVNDTipLabel: UILabel!
    @IBOutlet private weak var remitterDirectTextField: DropDownInputText!
    @IBOutlet private weak var remitterDirectErrorLabel: UILabel!
    @IBOutlet private weak var directViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var directView: UIView!
    @IBOutlet private weak var remitterBankCardTop: NSLayoutConstraint!
    @IBOutlet private weak var remitterBankCardHeight: NSLayoutConstraint!
    @IBOutlet private weak var remitterNameTextFieldTop: NSLayoutConstraint!
    @IBOutlet private weak var remitterNameTextFieldHeight: NSLayoutConstraint!
    
    var depositType: DepositSelection?
    var paymentIdentity: String!
    var isStarInputAmount: Bool = false
    var terminateAlertMessage = ""
    
    var playerLocaleConfiguration = DI.resolve(PlayerLocaleConfiguration.self)!
    var alert: AlertProtocol = DI.resolve(Alert.self)!
    
    private var disposeBag = DisposeBag()

    private let offlineViewModel = DI.resolve(OfflineViewModel.self)!
    private let onlineViewModel = DI.resolve(ThirdPartyDepositViewModel.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
        
        initUI()
        localize()

        switch depositType {
        case is OfflinePayment:
            offlineViewModel.unwindSegueId = "unwindToDeposit"
            bindOfflineViewModel()
            terminateAlertMessage = Localize.string("deposit_offline_termniate")
        case is OnlinePayment:
            initOnlineUI()
            bindThirdPartyViewModel()
            terminateAlertMessage = getTerminateAlertMessage(by: playerLocaleConfiguration.getSupportLocale(), paymentName: depositType!.name)
        
        default:
            offlineViewModel.unwindSegueId = "unwindToNotificationDetail"
            bindOfflineViewModel()
            terminateAlertMessage = Localize.string("deposit_offline_termniate")
            break
        }
    }
    
    private func initUI() {
        titleLabel.text = Localize.string("deposit_offline_step1_title")
        selectDepositBankLabel.text = Localize.string("deposit_selectbank")
        myDepositInfo.text = Localize.string("deposit_my_account_detail")
        
        remitterBankTextField.setTitle(Localize.string("deposit_bankname_placeholder"))
        remitterBankTextField.isSearchEnable = true

        remitterNameTextField.setTitle(Localize.string("deposit_name"))

        remitterDirectTextField.setTitle(Localize.string("deposit_bankname_placeholder"))

        remitterBankCardNumberTextField.setTitle(Localize.string("deposit_accountlastfournumber"))
        remitterBankCardNumberTextField.setKeyboardType(.numberPad)
        remitterBankCardNumberTextField.maxLength = 4
        remitterBankCardNumberTextField.numberOnly = true
        
        remitterBankCardHeight.constant = Theme.shared.getRemitterBankCardHeight(by: playerLocaleConfiguration.getSupportLocale())

        remitterAmountTextField.setTitle(Localize.string("deposit_amount"))
        remitterAmountTextField.setKeyboardType(.numberPad)
        amountTextOnlyInputNumber()

        depositConfirmButton.setTitle(Localize.string("deposit_offline_step1_button"), for: .normal)
        depositConfirmButton.isValid = false
        
        remitterAmountDropDown.setTitle(Localize.string("deposit_amount"))
        remitterAmountDropDown.isSearchEnable = false
        
        depositTableView.rowHeight = UITableView.automaticDimension
        
        depositTableView.rx
            .observe(\.contentSize)
            .map { $0.height }
            .subscribe(onNext: { [weak self] in
                self?.constraintBankTableHeight.constant = $0
            })
            .disposed(by: disposeBag)
    }

    private func localize() {
        if playerLocaleConfiguration.getCultureCode() == SupportLocale.China.init().cultureCode() {
            withdrawalVNDTipLabel.isHidden = true
        }
    }
    
    private func getTerminateAlertMessage(by playerLocale: SupportLocale, paymentName: String) -> String {
        switch playerLocaleConfiguration.getSupportLocale() {
        case is SupportLocale.Vietnam:
            return Localize.string("deposit_payment_terminate", paymentName)
        case is SupportLocale.China, is SupportLocale.Unknown:
            fallthrough
        default:
            return Localize.string("deposit_online_terminate")
        }
    }
    
    private func bindOfflineViewModel() {
        offlinePaymentGatewayBinding()
        remitterBankBinding()
        offlineTextFieldBinding()
        amountLimitationBinding()
        validateOfflineInputBinding()
        offlineConfirmButtonBinding()
        
        offlineViewModel.errors().subscribe(onNext: { [weak self] error in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func bindThirdPartyViewModel() {
        Observable.just(paymentIdentity).bind(to: onlineViewModel.input.paymentIdentity).disposed(by: disposeBag)
        onlinePaymentGatewayBinding()
        onlineAmountLimitationBinding()
        onlineTextFieldBinding()
        validateOnineInputBinding()
        onlineConfirmButtonBinding()

        onlineViewModel.output.selectPaymentGateway.drive(onNext: displayRemitType).disposed(by: disposeBag)
        onlineViewModel.errors().subscribe(onNext: { [weak self] error in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
        remitterBankTextField.selectedID.bind(to: onlineViewModel.input.selectBankCode).disposed(by: disposeBag)
        remitterDirectTextField.selectedID.bind(to: onlineViewModel.input.selectBankCode).disposed(by: disposeBag)
    }

    private func displayRemitType(gateway: PaymentsDTO.Gateway) {
        switch gateway.remitType {
        case PaymentsDTO.RemitType.normal:
            setFromBankView(isHidden: true)
            setDirectToView(isHidden: true)
            setOnlyAmountView(isHidden: false)
            
            remitterBankCardNumberTextField.visibility = gateway.isAccountNumberDenied ? .gone : .visible
            
        case PaymentsDTO.RemitType.frombank:
            setFromBankView(isHidden: false, remitBank: gateway.remitBank)
            setDirectToView(isHidden: true)
            setOnlyAmountView(isHidden: false)
            
        case PaymentsDTO.RemitType.directto:
            setFromBankView(isHidden: true)
            setDirectToView(isHidden: false, remitBank: gateway.remitBank)
            setOnlyAmountView(isHidden: false)
            
        case PaymentsDTO.RemitType.onlyamount:
            setFromBankView(isHidden: true)
            setDirectToView(isHidden: true)
            setOnlyAmountView(isHidden: true)
        default:
            break
        }
    }

    private func setFromBankView(isHidden: Bool, remitBank: [PaymentsDTO.RemitBankCode] = []) {
        remitterBankTextField.isHidden = isHidden
        remitterBankTextField.isSearchEnable = false
        remitterBankTextField.optionIds = remitBank.map{ $0.bankCode }
        remitterBankTextField.optionArray = remitBank.map{ $0.name }
        constraintremitterBankTextFieldHeight.constant = isHidden ? 0 : 60
        constraintremitterBankTextFieldTop.constant = isHidden ? 0 : 16
    }

    private func setDirectToView(isHidden: Bool, remitBank: [PaymentsDTO.RemitBankCode] = []) {
        remitterDirectTextField.isSearchEnable = false
        remitterDirectTextField.optionIds = remitBank.map{ $0.bankCode }
        remitterDirectTextField.optionArray = remitBank.map{ $0.name }
        directViewHeight.constant = isHidden ? 0 : 110
        directView.isHidden = isHidden
    }
    
    private func setOnlyAmountView(isHidden: Bool) {
        remitterNameTextField.isHidden = isHidden
        remitterNameTextFieldHeight.constant = isHidden ? 0 : 60
        remitterNameTextFieldTop.constant = isHidden ? 0 : 12
        remitterBankCardNumberTextField.isHidden = isHidden
        remitterBankCardHeight.constant = isHidden ? 0 : Theme.shared.getRemitterBankCardHeight(by: playerLocaleConfiguration.getSupportLocale())
        remitterBankCardTop.constant = isHidden ? 0 : 12
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
    
    @objc func back() {
        alert.show(Localize.string("common_confirm_cancel_operation"), terminateAlertMessage, confirm: {[weak self] in
            self?.disposeBag = DisposeBag()
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: { })
    }
    
    //MARK: Online
    private func initOnlineUI() {
        titleLabel.text = depositType?.name
        selectDepositBankLabel.text = Localize.string("deposit_select_method")
    }
    
    private func onlinePaymentGatewayBinding() {
        onlineViewModel.output.paymentGateways.drive(depositTableView.rx.items(cellIdentifier: String(describing: DepositMethodTableViewCell.self), cellType: DepositMethodTableViewCell.self)) { index, paymetGateway, cell in
            cell.setUp(onlinePaymentGatewayItemViewModel: paymetGateway)
        }.disposed(by: disposeBag)
        
        onlineViewModel.output.paymentGateways.drive(onNext: { [weak self] data in
            guard let self = self else { return }
            
            self.depositTableView.layoutIfNeeded()
            self.depositTableView.addTopBorder()
            self.depositTableView.addBottomBorder()
        }).disposed(by: disposeBag)
        
        Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(OnlinePaymentGatewayItemViewModel.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            self.onlineViewModel.input.selectPaymentGateway.onNext(data.gateway)
            self.depositTableView.reloadData()
        }.disposed(by: disposeBag)
    }
    
    private func onlineAmountLimitationBinding() {
        onlineViewModel.output.depositAmountHintText
            .drive(depositAmountHintLabel.rx.text)
            .disposed(by: disposeBag)
        
        onlineViewModel.output.floatAllow.drive(onNext: { [weak self] floatAllow in
            self?.gatewayAndFloatAllowDidChange(floatAllow)
        }).disposed(by: disposeBag)
        
        onlineViewModel.output.cashOption.drive(onNext: { [weak self] list in
            if let list = list {
                self?.remitterAmountDropDown.isHidden = false
                self?.remitterAmountTextField.isHidden = true
                self?.remitterAmountDropDown.optionArray = list.map {
                    $0.decimalValue.currencyFormatWithoutSymbol(maximumFractionDigits: 0)
                }
            } else {
                self?.remitterAmountDropDown.isHidden = true
                self?.remitterAmountTextField.isHidden = false
            }
        }).disposed(by: disposeBag)
    }
    
    private func gatewayAndFloatAllowDidChange(_ floatAllow: Bool?) {
        remitterHintLabel.isHidden = !(floatAllow ?? false)
        cleanAmountTextFieldValue()
        remitterAmountTextField.textContent.endEditing(true)
        if floatAllow == true {
            remitterAmountTextField.setKeyboardType(.decimalPad)
            amountTextCanInputDecimalPoint()
        } else {
            remitterAmountTextField.setKeyboardType(.numberPad)
            amountTextOnlyInputNumber()
        }
    }
    
    private func cleanAmountTextFieldValue() {
        remitterAmountTextField.setContent("")
        onlineViewModel.input.remittance.onNext("")
        remitterAmountTextField.adjustPosition()
    }
    
    private func amountTextCanInputDecimalPoint() {
        remitterAmountTextField.editingChangedHandler = { [weak self] (str) in
            guard let amount = str.currencyAmountToDouble() else {
                return
            }
            let strWithSeparator = str.replacingOccurrences(of: ",", with: "")
            self?.remitterAmountTextField.textContent.text = strWithSeparator.contains(".") ? str : amount.currencyFormatWithoutSymbol()
        }
        remitterAmountTextField.shouldChangeCharactersIn = {(textField, range, string) -> Bool in
            let candidate = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: "")
            if candidate == "" { return true }
            let isWellFormatted = candidate.range(of: RegularFormat.currencyFormatWithTwoDecimal.rawValue, options: .regularExpression) != nil
            return isWellFormatted
        }
    }
    
    private func amountTextOnlyInputNumber() {
        remitterAmountTextField.editingChangedHandler = { [weak self] (str) in
            guard let amount = Double(str.replacingOccurrences(of: ",", with: ""))?.currencyFormatWithoutSymbol() else { return }
            self?.remitterAmountTextField.textContent.text = amount
        }

        remitterAmountTextField.shouldChangeCharactersIn = {(textField, range, string) -> Bool in
            let candidate = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: "")
            if candidate == "" { return true }
            let isWellFormatted = candidate.range(of: RegularFormat.currencyFormat.rawValue, options: .regularExpression) != nil
            return isWellFormatted
        }
    }
    
    private func onlineTextFieldBinding() {
        onlineViewModel.output.remittance.drive(remitterAmountDropDown.text).disposed(by: disposeBag)
        onlineViewModel.output.remitterName.drive(remitterNameTextField.text).disposed(by: disposeBag)
        onlineViewModel.output.remitterName.drive(onNext: { [weak self] name in
            if name.isNotEmpty {
                self?.remitterNameTextField.adjustPosition()
            }
        }).disposed(by: disposeBag)
        onlineViewModel.output.remittance.drive(onNext: {[weak self] remittance in
            if remittance.isNotEmpty {
                self?.remitterAmountDropDown.adjustPosition()
            }
        }).disposed(by: disposeBag)
        
        remitterAmountDropDown.text.bind(to: onlineViewModel.input.remittance).disposed(by: disposeBag)
        remitterAmountTextField.text.bind(to: onlineViewModel.input.remittance).disposed(by: disposeBag)
        
        remitterAmountTextField.text
            .subscribe(onNext: { [weak self] in
                if self?.isStarInputAmount == false, $0.count > 0 {
                    self?.isStarInputAmount = true
                }
            })
            .disposed(by: disposeBag)
        
        remitterNameTextField.text.bind(to: onlineViewModel.input.remitterName).disposed(by: disposeBag)
        remitterBankCardNumberTextField.text.bind(to: onlineViewModel.input.remitterBankCardNumber).disposed(by: disposeBag)
    }
    
    private func validateOnineInputBinding() {
        onlineViewModel.output.remitterNameValid.drive { [weak self] (isValid) in
            guard let `self` = self, let accountNameException = isValid, self.remitterNameTextField.isEdited else {
                self?.remitterNameErrorLabel.text = ""
                return
            }
            let message = AccountPatternGeneratorFactory.transform(self.offlineViewModel.accountPatternGenerator, accountNameException)
            self.remitterNameErrorLabel.text = message
        }.disposed(by: disposeBag)
        
        Driver.combineLatest(
            onlineViewModel.output.selectPaymentGateway,
            onlineViewModel.output.remittanceValid
        )
        .drive(onNext: { [weak self] (gatewayDTO, isValid) in
            guard let self = self,
                  gatewayDTO.cash is CashType.Input ? self.isStarInputAmount : true
            else { return }
            
            switch isValid {
            case .overLimitation:
                self.remitterAmountErrorLabel.text = Localize.string("deposit_limitation_hint")
            case .empty:
                self.remitterAmountErrorLabel.text = Localize.string("common_field_must_fill")
            default:
                self.remitterAmountErrorLabel.text = ""
            }
        })
        .disposed(by: disposeBag)
        
        onlineViewModel.output
            .onlineDataValid
            .drive(depositConfirmButton.rx.valid)
            .disposed(by: disposeBag)
    }
    
    private func onlineConfirmButtonBinding() {
        depositConfirmButton.rx.throttledTap.bind(to: onlineViewModel.input.confirmTrigger).disposed(by: disposeBag)
        onlineViewModel.output.webPath.drive().disposed(by: disposeBag)
        onlineViewModel.output.inProgress.drive(depositConfirmButton.rx.valid).disposed(by: disposeBag)
    }
    
    //MARK: Offline
    private func offlinePaymentGatewayBinding() {
        offlineViewModel.output.paymentGateway.drive(depositTableView.rx.items(cellIdentifier: String(describing: DepositMethodTableViewCell.self), cellType: DepositMethodTableViewCell.self)) { index, bank, cell in
            cell.setUp(offlinePaymentGatewayItemViewModel: bank)
        }.disposed(by: disposeBag)
        
        offlineViewModel.output.paymentGateway.drive(onNext: { [weak self] data in
            guard let self = self else { return }
            self.depositTableView.layoutIfNeeded()
            self.depositTableView.addTopBorder()
            self.depositTableView.addBottomBorder()
        }).disposed(by: disposeBag)
        
        Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(OfflinePaymentGatewayItemViewModel.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            self.offlineViewModel.input.selectPaymentGateway.onNext(data.bank)
            self.depositTableView.reloadData()
        }.disposed(by: disposeBag)
    }
    
    private func remitterBankBinding() {
        offlineViewModel.output.remitterBanks.drive(onNext: { [weak self] banks in
            self?.remitterBankTextField.optionArray = banks.map { $0.name }
        }).disposed(by: disposeBag)
    }
    
    private func offlineTextFieldBinding() {
        remitterBankTextField.text.bind(to: offlineViewModel.input.remitterBank).disposed(by: disposeBag)
        remitterNameTextField.text.bind(to: offlineViewModel.input.remitterName).disposed(by: disposeBag)
        remitterBankCardNumberTextField.text.bind(to: offlineViewModel.input.remitterBankCardNumber).disposed(by: disposeBag)
        remitterAmountTextField.text.bind(to: offlineViewModel.input.amount).disposed(by: disposeBag)
        offlineViewModel.output.remitterName.drive(remitterNameTextField.text).disposed(by: disposeBag)
        offlineViewModel.output.remitterName.drive(onNext: { [weak self] name in
            if name.isNotEmpty {
                self?.remitterNameTextField.adjustPosition()
            }
        }).disposed(by: disposeBag)
    }
    
    private func amountLimitationBinding() {
        offlineViewModel.output.depositLimit.drive(onNext: { [weak self] amountRange in
            self?.depositAmountHintLabel.text = String(format: Localize.string("deposit_offline_step1_tips"),
                                                  amountRange.min.description(),
                                                  amountRange.max.description())
        }).disposed(by: disposeBag)
    }
    
    private func validateOfflineInputBinding() {
        offlineViewModel.output.bankValid.drive { [weak self] (isValid) in
            guard let `self` = self, let accountNameException = isValid, self.remitterBankTextField.isEdited else {
                self?.remitterBankErrorLabel.text = ""
                return
            }
            let message = AccountPatternGeneratorFactory.transform(self.offlineViewModel.accountPatternGenerator, accountNameException)
            self.remitterBankErrorLabel.text = message
        }.disposed(by: disposeBag)
        
        offlineViewModel.output.userNameValid.drive { [weak self] (isValid) in
            guard let `self` = self, let accountNameException = isValid, self.remitterNameTextField.isEdited else {
                self?.remitterNameErrorLabel.text = ""
                return
            }
            let message = AccountPatternGeneratorFactory.transform(self.offlineViewModel.accountPatternGenerator, accountNameException)
            self.remitterNameErrorLabel.text = message
        }.disposed(by: disposeBag)
        
        offlineViewModel.output.amountValid.drive { [weak self] (isValid) in
            guard let `self` = self, self.remitterAmountTextField.isEdited else { return }
            switch isValid {
            case .overLimitation:
                self.remitterAmountErrorLabel.text = Localize.string("deposit_limitation_hint")
            case .empty:
                self.remitterAmountErrorLabel.text = Localize.string("common_field_must_fill")
            default:
                self.remitterAmountErrorLabel.text = ""
            }
        }.disposed(by: disposeBag)
        
        offlineViewModel.output
            .offlineDataValid
            .drive(depositConfirmButton.rx.valid)
            .disposed(by: disposeBag)
    }
    
    private func offlineConfirmButtonBinding() {
        depositConfirmButton.rx.tap.bind(to: offlineViewModel.input.confirmTrigger).disposed(by: disposeBag)
        offlineViewModel.output.memo.drive().disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
            if let dest = segue.destination as? DepositThirdPartWebViewController {
                dest.url = sender as? String
            }
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
