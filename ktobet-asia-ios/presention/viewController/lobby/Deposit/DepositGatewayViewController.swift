import UIKit
import RxSwift
import SharedBu

class DepositGatewayViewController: APPViewController {
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
    @IBOutlet private weak var depositLimitLabel: UILabel!
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
    
    var depositType: DepositSelection?
    var paymentIdentity: String!
    var isStarInputAmount: Bool = false
    
    fileprivate var offlineViewModel = DI.resolve(OfflineViewModel.self)!
    fileprivate var onlineViewModel = DI.resolve(ThirdPartyDepositViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
        
        initUI()
        
        switch depositType {
        case is OfflinePayment:
            offlineViewModel.unwindSegueId = "unwindToDeposit"
            bindOfflineViewModel()
        case is OnlinePayment:
            initOnlineUI()
            bindThirdPartyViewModel()
        default:
            offlineViewModel.unwindSegueId = "unwindToNotificationDetail"
            bindOfflineViewModel()
            break
        }
    }
    
    private func bindOfflineViewModel() {
        offlinePaymentGatewayBinding()
        remitterBankBinding()
        offlineTextFieldBinding()
        amountLimitationBinding()
        validateOfflineInputBinding()
        offlineConfirmButtonBinding()
        
        offlineViewModel.errors().subscribe(onNext: {[weak self] error in
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
        
        onlineViewModel.errors().subscribe(onNext: {[weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        if error is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func notifyTryLaterAndPopBack() {
        Alert.show(nil, Localize.string("deposit_notify_request_later"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: nil)
    }
    
    private func initUI() {
        titleLabel.text = Localize.string("deposit_offline_step1_title")
        selectDepositBankLabel.text = Localize.string("deposit_selectbank")
        myDepositInfo.text = Localize.string("deposit_my_account_detail")
        
        remitterBankTextField.setTitle(Localize.string("deposit_bankname_placeholder"))
        remitterBankTextField.isSearchEnable = true
        
        remitterNameTextField.setTitle(Localize.string("deposit_name"))
        
        remitterBankCardNumberTextField.setTitle(Localize.string("deposit_accountlastfournumber"))
        remitterBankCardNumberTextField.setKeyboardType(.numberPad)
        remitterBankCardNumberTextField.maxLength = 4
        remitterBankCardNumberTextField.numberOnly = true
        remitterBankCardNumberTextField.isPasteble = false

        remitterAmountTextField.setTitle(Localize.string("deposit_amount"))
        remitterAmountTextField.setKeyboardType(.numberPad)
        
        depositConfirmButton.setTitle(Localize.string("deposit_offline_step1_button"), for: .normal)
        depositConfirmButton.isValid = false
        
        remitterAmountDropDown.setTitle(Localize.string("deposit_amount"))
        remitterAmountDropDown.isSearchEnable = false
    }
    
    @objc func back() {
        Alert.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_offline_termniate"), confirm: {[weak self] in
            self?.disposeBag = DisposeBag()
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: { })
    }
    
    //MARK: Online
    private func initOnlineUI() {
        remitterBankTextField.isHidden = true
        constraintremitterBankTextFieldHeight.constant = 0
        constraintremitterBankTextFieldTop.constant = 0
        titleLabel.text = depositType?.name
        selectDepositBankLabel.text = Localize.string("deposit_select_method")
    }
    
    private func onlinePaymentGatewayBinding() {
        onlineViewModel.output.paymentGateways.drive(depositTableView.rx.items(cellIdentifier: String(describing: DepositMethodTableViewCell.self), cellType: DepositMethodTableViewCell.self)) { index, paymetGateway, cell in
            cell.setUp(onlinePaymentGatewayItemViewModel: paymetGateway)
        }.disposed(by: disposeBag)
        
        onlineViewModel.output.paymentGateways.drive(onNext: { [weak self] data in
            guard let self = self else { return }
            self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
            self.depositTableView.layoutIfNeeded()
            self.depositTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
        }).disposed(by: disposeBag)
        
        Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(OnlinePaymentGatewayItemViewModel.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            self.onlineViewModel.input.selectPaymentGateway.onNext(data.gateway)
            self.depositTableView.reloadData()
        }.disposed(by: disposeBag)
    }
    
    private func onlineAmountLimitationBinding() {
        onlineViewModel.output.depositLimit.drive(onNext: { [weak self] amountRange in
            guard let amountRange = amountRange else {
                self?.depositLimitLabel.text = ""
                return
            }
            
            self?.depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"),
                                                  amountRange.min.description(),
                                                  amountRange.max.description())
        }).disposed(by: disposeBag)
        
        onlineViewModel.output.cashOption.drive(onNext: { [weak self] list in
            if let list = list {
                self?.remitterAmountDropDown.isHidden = false
                self?.remitterAmountTextField.isHidden = true
                self?.remitterAmountErrorLabel.isHidden = true
                self?.depositLimitLabel.text = nil
                self?.remitterAmountDropDown.optionArray = list.map { String($0.intValue) }
            } else {
                self?.remitterAmountDropDown.isHidden = true
                self?.remitterAmountTextField.isHidden = false
                self?.remitterAmountErrorLabel.isHidden = false
            }
        }).disposed(by: disposeBag)
        
        onlineViewModel.output.floatAllow.drive(onNext: { [weak self] floatAllow in
            self?.gatewayAndFloatAllowDidChange(floatAllow)
        }).disposed(by: disposeBag)
    }
    
    private func gatewayAndFloatAllowDidChange(_ floatAllow: FloatAllow?) {
        remitterHintLabel.text = floatAllow?.hint
        cleanAmountTextFieldValue()
        remitterAmountTextField.textContent.endEditing(true)
        if floatAllow?.isAllowed == true {
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
        remitterAmountTextField.text.subscribe(onNext: { [weak self] in
            if self?.isStarInputAmount == false, $0.count > 0 {
                self?.isStarInputAmount = true
            }
        }).disposed(by: disposeBag)
        remitterNameTextField.text.bind(to: onlineViewModel.input.remitterName).disposed(by: disposeBag)
        remitterBankCardNumberTextField.text.bind(to: onlineViewModel.input.remitterBankCardNumber).disposed(by: disposeBag)
    }
    
    private func validateOnineInputBinding() {
        onlineViewModel.output.remitterNameValid.drive { [weak self] (isValid) in
            guard let `self` = self, let accountNameException = isValid, self.remitterNameTextField.isEdited else {
                self?.remitterNameErrorLabel.text = ""
                return
            }
            let message = AccountPatternGeneratorFactory.transfer(self.offlineViewModel.accountPatternGenerator, accountNameException)
            self.remitterNameErrorLabel.text = message
        }.disposed(by: disposeBag)
        
        onlineViewModel.output.remittanceValid.drive { [weak self] (isValid) in
            guard let `self` = self, self.isStarInputAmount else { return }
            switch isValid {
            case .overLimitation:
                self.remitterAmountErrorLabel.text = Localize.string("deposit_limitation_hint")
            case .empty:
                self.remitterAmountErrorLabel.text = Localize.string("common_field_must_fill")
            default:
                self.remitterAmountErrorLabel.text = ""
            }
        }.disposed(by: disposeBag)
        
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
            self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
            self.depositTableView.layoutIfNeeded()
            self.depositTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
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
            self?.depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"),
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
            let message = AccountPatternGeneratorFactory.transfer(self.offlineViewModel.accountPatternGenerator, accountNameException)
            self.remitterBankErrorLabel.text = message
        }.disposed(by: disposeBag)
        
        offlineViewModel.output.userNameValid.drive { [weak self] (isValid) in
            guard let `self` = self, let accountNameException = isValid, self.remitterNameTextField.isEdited else {
                self?.remitterNameErrorLabel.text = ""
                return
            }
            let message = AccountPatternGeneratorFactory.transfer(self.offlineViewModel.accountPatternGenerator, accountNameException)
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
