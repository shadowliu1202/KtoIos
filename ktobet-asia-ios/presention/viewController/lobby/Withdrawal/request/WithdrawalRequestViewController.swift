import UIKit
import RxSwift
import SharedBu


class WithdrawalRequestViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalRequest"
    @IBOutlet private weak var withdrawalStep1TitleLabel: UILabel!
    @IBOutlet private weak var withdrawalTitleLabel: UILabel!
    @IBOutlet private weak var nameLabel: LockInputText!
    @IBOutlet private weak var withdrawalAmountTextField: InputText!
    @IBOutlet private weak var withdrawalAmountErrorLabel: UILabel!
    @IBOutlet private weak var withdrawalLimitLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    
    private var viewModel = DI.resolve(WithdrawalRequestViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var account: WithdrawalAccount!
    var withdrawalLimits: WithdrawalLimits!
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        viewModel.getBalance().subscribe().disposed(by: disposeBag)
        withdrawalLimitationDataBinding()
        validateInputTextField()
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalRequestConfirmViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalRequestConfirmViewController {
                dest.account = sender as? WithdrawalAccount
                dest.amount = self.viewModel.relayWithdrawalAmount.value
                dest.withdrawalLimits = self.withdrawalLimits
            }
        }
    }
    
    // MARK: METHOD
    private func initUI() {
        nameLabel.setTitle(Localize.string("withdrawal_accountrealname"))
        nameLabel.setContent(account.accountName)
        viewModel.relayName.accept(account.accountName)
        withdrawalStep1TitleLabel.text = Localize.string("withdrawal_step1_title_1")
        withdrawalTitleLabel.text = Localize.string("withdrawal_step1_title_2")
        withdrawalAmountTextField.setTitle(Localize.string("withdrawal_amount"))
        withdrawalAmountTextField.setKeyboardType(UIKeyboardType.decimalPad)
        nextButton.setTitle(Localize.string("common_next"), for: .normal)
        nextButton.isValid = false
        (self.withdrawalAmountTextField.text <-> self.viewModel.relayWithdrawalAmount).disposed(by: self.disposeBag)
        withdrawalAmountTextField.editingChangedHandler = { (str) in
            guard let amount = str.currencyAmountToDouble() else { return }
            let strWithSeparator = str.replacingOccurrences(of: ",", with: "")
            let maxmumAmount:Double = 9999999
            amount > maxmumAmount ? self.viewModel.relayWithdrawalAmount.accept(maxmumAmount.currencyFormatWithoutSymbol()) : self.viewModel.relayWithdrawalAmount.accept(strWithSeparator.contains(".") ? str : amount.currencyFormatWithoutSymbol(precision: 0))
        }
        
        let formatter = NumberFormatter()
        withdrawalAmountTextField.shouldChangeCharactersIn = {(textField, range, string) -> Bool in
            let candidate = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: "")
            if candidate == "" { return true }
            let isWellFormatted = candidate.range(of: RegularFormat.currencyFormatWithTwoDecimal.rawValue, options: .regularExpression) != nil
            if isWellFormatted,
                let value = formatter.number(from: candidate)?.doubleValue,
                value >= 0,
                value < 99999999 {
                    return true
            }

            return false
        }
        
        nextButton.rx.tap.subscribe (onNext: {[weak self] in
            self?.performSegue(withIdentifier: WithdrawalRequestConfirmViewController.segueIdentifier, sender: self?.account)
        }).disposed(by: disposeBag)
        
        viewModel.isRealNameEditable().subscribe(onSuccess: { [weak self] (editable) in
            guard let `self` = self else {return}
            if editable {
                let gesture =  UITapGestureRecognizer(target: self, action:  #selector(self.editNameAction))
                self.nameLabel.addGestureRecognizer(gesture)
            }
        }, onError: { [weak self]  (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
    
    private func withdrawalLimitationDataBinding() {
        viewModel.getWithdrawalLimitation().subscribe { [weak self] (withdrawalLimits) in
            guard let self = self else { return }
            self.withdrawalLimits = withdrawalLimits
            self.withdrawalLimitLabel.text = String(format: Localize.string("withdrawal_amount_range"), withdrawalLimits.singleCashMinimum.amount.currencyFormatWithoutSymbol(precision: 2), withdrawalLimits.singleCashMaximum.amount.currencyFormatWithoutSymbol(precision: 2))
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    private func validateInputTextField() {
        viewModel.event().amountValid.subscribe { [weak self] (isValid) in
            guard let amountStatus = isValid.element, self?.withdrawalAmountTextField.isEdited ?? false else { return }
            var message = ""
            switch amountStatus {
            case .amountBelowRange:
                message = Localize.string("withdrawal_input_lowermin")
            case .amountBeyondRange:
                message = Localize.string("withdrawal_input_overmax")
            case .amountExceedDailyLimit:
                message = Localize.string("withdrawal_amount_exceed_daily_limit")
            case .empty:
                message = Localize.string("common_field_must_fill")
            case .notEnoughBalance:
                message = Localize.string("withdrawal_balance_not_enough")
            default:
                message = ""
            }
            
            self?.withdrawalAmountErrorLabel.text = message
        }.disposed(by: disposeBag)
                
        viewModel.event()
            .dataValid
            .bind(to: nextButton.rx.valid)
            .disposed(by: disposeBag)
    }
    
    @objc func editNameAction() {
        let title = Localize.string("withdrawal_bankcard_change_confirm_title")
        let message = Localize.string("withdrawal_bankcard_change_confirm_content")
        Alert.show(title, message, confirm: {
            //TODO: go edit profile viewcontroler.
        }, cancel: nil)
    }
    
}
