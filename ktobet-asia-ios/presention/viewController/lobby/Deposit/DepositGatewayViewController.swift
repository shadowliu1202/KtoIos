import UIKit
import RxSwift
import SharedBu

class DepositGatewayViewController: UIViewController {
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
    @IBOutlet private weak var depositConfirmButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var constraintBankTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintAllBankTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintremitterBankTextFieldHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintremitterBankTextFieldTop: NSLayoutConstraint!
    @IBOutlet private weak var remitterBankErrorLabel: UILabel!
    @IBOutlet private weak var remitterNameErrorLabel: UILabel!
    @IBOutlet private weak var remitterBankCardNumberErrorLabel: UILabel!
    @IBOutlet private weak var remitterAmountErrorLabel: UILabel!

    var depositType: DepositType?
    
    fileprivate var selectedIndex = 0
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var confirmHandler: (() -> ())?

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.selectedType = depositType
        if let depositType = depositType, depositType.supportType == .OfflinePayment {
            NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
            
            offlineDataBinding()
            offlineEventHandle()
            banksDataBinding()
            validateOfflineInputTextField()
            setLimitation(depositType.method.limitation)
            titleLabel.text = Localize.string("deposit_offline_step1_title")
            selectDepositBankLabel.text = Localize.string("deposit_selectbank")
            confirmHandler = {
                self.performSegue(withIdentifier: DepositOfflineConfirmViewController.segueIdentifier, sender: nil)
            }
        } else if let depositType = depositType {
            NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
            
            remitterBankTextField.isHidden = true
            constraintremitterBankTextFieldHeight.constant = 0
            constraintremitterBankTextFieldTop.constant = 0
            titleLabel.text = depositType.method.name
            selectDepositBankLabel.text = Localize.string("deposit_select_method")
            thirdPartDataBinding()
            thirdPartEventHandler()
            validateOnlineInputTextField()
            confirmHandler = {[weak self] in
                self?.depositOnline()
            }
        }
        
        initUI()
    }
    
    @objc func back() {
        Alert.show(Localize.string("common_confirm_cancel_operation"), Localize.string("deposit_offline_termniate"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: {})
    }

    // MARK: BUTTON ACTION
    @IBAction func depositConfirm(_ sender: Any) {
        confirmHandler?()
    }

    // MARK: METHOD
    fileprivate func initUI() {
        (remitterBankTextField.text <-> viewModel.relayBankName).disposed(by: disposeBag)
        (self.remitterNameTextField.text <-> self.viewModel.relayName).disposed(by: self.disposeBag)
        (self.remitterAmountTextField.text <-> self.viewModel.relayBankAmount).disposed(by: self.disposeBag)
        remitterAmountTextField.editingChangedHandler = { (str) in
            guard let amount = Double(str.replacingOccurrences(of: ",", with: ""))?.currencyFormatWithoutSymbol() else { return }
            self.viewModel.relayBankAmount.accept(amount)
        }
        
        scrollView.backgroundColor = UIColor.black_two
        depositTableView.addTopBorder(size: 1, color: UIColor.dividerCapeCodGray2)
        myDepositInfo.text = Localize.string("deposit_my_account_detail")
        remitterBankTextField.setTitle(Localize.string("deposit_bankname_placeholder"))
        remitterBankTextField.isSearchEnable = true
        remitterBankTextField.selectedID.subscribe(onNext: { [weak self] (bankId) in
            if let id = bankId {
                self?.viewModel.relayBankId.accept(Int32(id))
            }
        }).disposed(by: disposeBag)
        remitterNameTextField.setTitle(Localize.string("deposit_name"))
        remitterBankCardNumberTextField.setTitle(Localize.string("deposit_accountlastfournumber"))
        remitterAmountTextField.setTitle(Localize.string("deposit_amount"))
        depositConfirmButton.setTitle(Localize.string("deposit_offline_step1_button"), for: .normal)
        depositConfirmButton.isValid = false
        remitterAmountTextField.setKeyboardType(UIKeyboardType.numberPad)
        remitterBankCardNumberTextField.setKeyboardType(.numberPad)
        remitterBankCardNumberTextField.maxLength = 4
        remitterBankCardNumberTextField.numberOnly = true
        remitterAmountTextField.numberOnly = true
        remitterAmountDropDown.optionArray = [WeiLaiProvidAmount.fifty, WeiLaiProvidAmount.oneHundred, WeiLaiProvidAmount.twoHundred].map({$0.rawValue})
        remitterAmountDropDown.setTitle(Localize.string("deposit_amount"))
        remitterAmountDropDown.isSearchEnable = false
        (remitterAmountDropDown.text <-> viewModel.dropdownAmount).disposed(by: disposeBag)
    }
    
    fileprivate func thirdPartDataBinding() {
        let getDepositOnlineBankAccountsObservable = viewModel.getDepositPaymentGateways(depositType: depositType!).catchError { error in
            self.handleUnknownError(error)
            return Single<[PaymentGateway]>.never() }.asObservable()
        
        getDepositOnlineBankAccountsObservable.bind(to: depositTableView.rx.items(cellIdentifier: String(describing: DepositMethodTableViewCell.self), cellType: DepositMethodTableViewCell.self)) { index, data, cell in
            cell.setUp(icon: "Default(32)", name: data.displayName, index: index, selectedIndex: self.selectedIndex)
        }.disposed(by: disposeBag)

        getDepositOnlineBankAccountsObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (data) in
                guard let self = self else { return }
                self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
                self.depositTableView.layoutIfNeeded()
                self.depositTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
                guard let firstSelectedMethod = data.first else { return }
                self.setDepositProvider(firstSelectedMethod)
        }).disposed(by: disposeBag)
        
        viewModel.paymentSlip.subscribe(onNext: { [weak self] (paymentSlip) in
            guard let limitation = paymentSlip?.depositLimitation else { return }
            self?.setLimitation(limitation)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func thirdPartEventHandler() {
        Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(PaymentGateway.self)).bind {[weak self] (indexPath, data) in
            guard let self = self else { return }
            guard let cell = self.depositTableView.cellForRow(at: indexPath) as? DepositMethodTableViewCell else { return }
            guard let lastCell = self.depositTableView.cellForRow(at: IndexPath(item: self.selectedIndex, section: 0)) as? DepositMethodTableViewCell else { return }
            lastCell.unSelectRow()
            cell.selectRow()
            self.selectedIndex = indexPath.row
            self.setDepositProvider(data)
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(depositTableView.rx.modelSelected(PaymentGateway.self), self.remitterAmountTextField.text).bind(onNext: { [weak self] (_, str) in
            guard let `self` = self, let amount = Double(str.replacingOccurrences(of: ",", with: ""))?.currencyFormatWithoutSymbol() else { return }
            self.viewModel.relayBankAmount.accept(amount)
        }).disposed(by: disposeBag)
    }
    
    private func setDepositProvider(_ gateway: PaymentGateway) {
        self.viewModel.selectedGateway = gateway
        self.updateDepositAmountInput(gateway)
    }
    
    private func updateDepositAmountInput(_ gateway: PaymentGateway) {
        if viewModel.needCashOption(gateway: gateway) {
            remitterAmountDropDown.isHidden = false
            remitterAmountTextField.isHidden = true
            remitterAmountErrorLabel.isHidden = true
            self.depositLimitLabel.text = nil
        } else {
            remitterAmountDropDown.isHidden = true
            remitterAmountTextField.isHidden = false
            remitterAmountErrorLabel.isHidden = false
        }
    }
    
    fileprivate func setLimitation(_ range: AmountRange) {
        self.depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"), range.min.description(), range.max.description())
    }

    fileprivate func offlineDataBinding() {
        let getDepositOfflineBankAccountsObservable = viewModel.getDepositOfflineBankAccounts().catchError { _ in Single<[OfflineBank]>.never() }.asObservable()
        getDepositOfflineBankAccountsObservable.bind(to: depositTableView.rx.items(cellIdentifier: String(describing: DepositMethodTableViewCell.self), cellType: DepositMethodTableViewCell.self)) { index, bank, cell in
            cell.setUp(icon: self.viewModel.getBankIcon(bank.bankId), name: bank.name, index: index, selectedIndex: self.selectedIndex)
        }.disposed(by: disposeBag)
        
        getDepositOfflineBankAccountsObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe { (data) in
                self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
                self.depositTableView.layoutIfNeeded()
                self.depositTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
                guard let firstSelectedBank = data.first else { return }
                self.viewModel.selectedReceiveBank = firstSelectedBank
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)
    }

    fileprivate func offlineEventHandle() {
        Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(OfflineBank.self)).bind { (indexPath, data) in
            self.depositTableView.deselectRow(at: indexPath, animated: true)
            guard let cell = self.depositTableView.cellForRow(at: indexPath) as? DepositMethodTableViewCell else { return }
            guard let lastCell = self.depositTableView.cellForRow(at: IndexPath(item: self.selectedIndex, section: 0)) as? DepositMethodTableViewCell else { return }
            lastCell.unSelectRow()
            cell.selectRow()
            self.selectedIndex = indexPath.row
            self.viewModel.selectedReceiveBank = data
        }.disposed(by: disposeBag)
    }

    fileprivate func banksDataBinding() {
        viewModel.getBanks().subscribe {[weak self] (tuple: [(Int, Bank)]) in
            self?.remitterBankTextField.optionArray = tuple.map{ $0.1.name }
            self?.remitterBankTextField.optionIds = tuple.map{ $0.0 }
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }

    fileprivate func validateOfflineInputTextField() {
        validateInputTextField()
        viewModel.event().bankValid.subscribe { [weak self] (isValid) in
            guard let isValid = isValid.element, self?.remitterBankTextField.isEdited ?? false else {
                self?.remitterBankErrorLabel.text = ""
                return
            }
            let message = isValid ? "" : Localize.string("common_field_must_fill")
            self?.remitterBankErrorLabel.text = message
        }.disposed(by: disposeBag)
        viewModel.event()
            .offlineDataValid
            .bind(to: depositConfirmButton.rx.valid)
            .disposed(by: disposeBag)
    }
    
    fileprivate func validateOnlineInputTextField() {
        validateInputTextField()
        viewModel.event()
            .onlinieDataValid
            .bind(to: depositConfirmButton.rx.valid)
            .disposed(by: disposeBag)
    }

    fileprivate func validateInputTextField() {
        viewModel.event().userNameValid.subscribe { [weak self] (isValid) in
            guard let `self` = self,  let accountNameException = isValid.element, self.remitterNameTextField.isEdited else { return }
            let message = AccountPatternGeneratorFactory.transfer(self.viewModel.accountPatternGenerator, accountNameException)
            self.remitterNameErrorLabel.text = message
        }.disposed(by: disposeBag)

        viewModel.event().amountValid.subscribe { [weak self] (isValid) in
            guard let isValid = isValid.element, self?.remitterAmountTextField.isEdited ?? false else { return }
            let message = isValid ? "" : self?.viewModel.relayBankAmount.value.count == 0 ? Localize.string("common_field_must_fill") : Localize.string("deposit_limitation_hint")
            self?.remitterAmountErrorLabel.text = message
        }.disposed(by: disposeBag)
    }
    
    fileprivate func depositOnline() {
        self.viewModel.depositOnline(depositTypeId: self.depositType?.paymentType.id ?? 0).subscribe { (url) in
            let title = Localize.string("common_kindly_remind")
            let message = Localize.string("deposit_thirdparty_transaction_remind")
            Alert.show(title, message, confirm: {
                self.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: url)
            }, cancel: nil)
        } onError: { [weak self] (error) in
            self?.handleError(error)
        }.disposed(by: disposeBag)
    }
    
    func handleError(_ error: Error) {
        let exception = ExceptionFactory.create(error)
        if exception is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            self.handleErrors(error)
        }
    }
    
    private func notifyTryLaterAndPopBack() {
        Alert.show(nil, Localize.string("deposit_notify_request_later"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: nil)
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositOfflineConfirmViewController.segueIdentifier {
            if let dest = segue.destination as? DepositOfflineConfirmViewController {
                var requestAmount: OfflineDepositCash
                do {
                    requestAmount = try OfflineDepositCashFactory.companion.create(originAmount: self.viewModel.relayBankAmount.value.toAccountCurrency())
                } catch {
                    print(error)
                    fatalError("OfflineDepositCashFactory got error = \(error.localizedDescription)")
                }
                let remitter = DepositRequest_.Remitter.init(name: self.viewModel.relayName.value,
                                                             accountNumber: self.viewModel.relayBankNumber.value)
                let depositRequest = DepositRequest_.init(remitter: remitter, amount: requestAmount, depositMethod: DepositMethod.init(type: PaymentType.OfflinePayment.init(), name: self.viewModel.relayBankName.value, limitation: AmountRange.init(min: viewModel.minAmountLimit.toAccountCurrency(), max: viewModel.maxAmountLimit.toAccountCurrency()), isFavorite: false), paymentToken: self.viewModel.selectedReceiveBank.paymentTokenId)
                dest.depositRequest = depositRequest
                dest.selectedReceiveBank = viewModel.selectedReceiveBank
            }
        }
        
        if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
            if let dest = segue.destination as? DepositThirdPartWebViewController {
                dest.url = sender as? String
            }
        }
    }
    
}
